###
Dialects are responsible for rendering an AST to a SQL string compatible with
a particular DBMS. They are rarely used directly, instead a query is usually bound
to an `engine <Engines>`_ that will delegate rendering to it's dialect instance.
###

fs = require('fs')

prefixIfNotEmpty = (prefix) ->
  (node) ->
    children = @renderNodeSet node
    if children then prefix + children else ''

class BaseDialect
  ###
  A dialect that isn't specific to a particular DBMS, but used as a base for both
  MySQL and Postgres.
  ###
  render: (node) ->
    type = node.__proto__
    name = type.constructor.name
    until @['render'+name]
      if 'Object' == name or not type
        throw new Error "Couldn't find a renderer for #{node.constructor.name}"
      type = type.__proto__
      name = type.constructor.name
    @['render'+name](node)

  renderString: (s) -> s

  renderIdentifier: (n) -> @quote(n.value)

  quote: (s) ->
    if s?.match(/\s|"|\./) or @isKeyword(s)
      return '"' + s.replace('"', '\\"') + '"'
    else
      s

  keywords = fs.readFileSync(__dirname + '/sql_keywords.txt', 'ascii').split('\n').filter(Boolean)

  isKeyword: (s) ->
    keywords.indexOf(s.toUpperCase()) isnt -1

  renderProjection: (p) ->
    if p.source?.alias?
      @quote(p.source.alias) + '.' + @render(p.field)
    else
      @renderNodeSet(p)

  renderNodeSet: (set) ->
    set.nodes.map((n) => @render n).filter((n) -> n).join(set.glue)
   
  renderParenthesizedNodeSet: (set) ->
    "(" + @renderNodeSet(set) + ")"

  renderAlias: (node) ->
    "#{@maybeParens @render node.obj} AS #{@render node.alias}"

  maybeParens: (it) -> if /\s/.exec it then "(#{it})" else it

  renderDistinct: (set) ->
    if not set.enable
      ''
    else if set.nodes.length
      "DISTINCT(#{@renderNodeSet set})"
    else
      'DISTINCT'

  renderSelectProjectionSet: (set) ->
    if not set.nodes.length
      '*'
    else
      @renderNodeSet set

  renderSqlFunction: (node) -> "#{@render node.name}#{@render node.arglist}"

  renderValueNode: (node) -> node.value

  renderParameter: (node) -> '?'

  renderSelect: prefixIfNotEmpty 'SELECT '
  renderUpdate: prefixIfNotEmpty 'UPDATE '
  renderInsert: prefixIfNotEmpty 'INSERT INTO '
  renderInsertData: prefixIfNotEmpty 'VALUES '
  renderDelete: prefixIfNotEmpty 'DELETE '
  renderUpdateSet: prefixIfNotEmpty 'SET '
  renderRelationSet: prefixIfNotEmpty 'FROM '
  renderWhere: prefixIfNotEmpty 'WHERE '
  renderGroupBy: prefixIfNotEmpty 'GROUP BY '
  renderOrderBySet: prefixIfNotEmpty 'ORDER BY '
  renderReturning: prefixIfNotEmpty 'RETURNING '

  renderLimit: (node) ->
    if node.value then "LIMIT " + node.value else ""

  renderOffset: (node) ->
    if node.value then "OFFSET " + node.value else ""

  renderBinary: (node) ->
    @render(node.left) + ' ' + @renderOp(node.op) + ' ' + @render(node.right)

  renderOp: (op) ->
    switch op.toLowerCase()
      when 'ne', '!=', '<>' then '!='
      when 'eq', '='   then '='
      when 'lt', '<'   then '<'
      when 'gt', '>'   then '>'
      when 'lte', '<=' then '<='
      when 'gte', '>=' then '>='
      when 'like' then 'LIKE'
      when 'ilike' then 'ILIKE'
      when 'in' then 'IN'
      when 'is' then 'IS'
      else throw new Error("Unsupported comparison operator: #{op}")

class AnyDBDialect extends BaseDialect
  {Select, Update, Delete, Insert} = require './nodes'

  render: (node) ->
    if node.constructor in [Select, Update, Delete, Insert]
      @paramCount = 1
    super node

  renderParameter: (node) ->
    "$#{@paramCount++}"

class PostgresDialect extends AnyDBDialect
  renderOp: (op) ->
    switch op.toLowerCase()
      when 'hasKey' then '?'
      when '->' then '->'
      else super op

class MySQLDialect extends AnyDBDialect

class SQLite3Dialect extends AnyDBDialect

module.exports =
  base: BaseDialect
  anyDB: AnyDBDialect
  postgres: PostgresDialect
  mysql: MySQLDialect
  sqlite3: SQLite3Dialect

