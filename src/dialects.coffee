###
Dialects are responsible for rendering an AST to a SQL string compatible with
a particular DBMS. They are rarely used directly, instead a query is usually bound
to an `engine <Engines>`_ that will delegate rendering to it's dialect instance.
###

read = require('fs').readFileSync
kwFile = __dirname + '/sql_keywords.txt'
keywords = read(kwFile, 'ascii').split('\n').filter(Boolean)

class BaseDialect
  constructor: ->
    @path = []

  render: (node) ->
    @path.push(node)
    name = node?.__proto__?.constructor?.name
    if name and custom = @['render' + name]
      string = custom.call(@, node)
    else
      string = node.render(@, @path)
    @path.pop(node)
    return string

  renderString: (s) -> s

  needsQuote = /\s|"|\./
  doubleQuote = /"/g

  quote: (s) ->
    if s?.match(needsQuote) or @isKeyword(s)
      return '"' + s.replace(doubleQuote, '\\"') + '"'
    else
      s

  isKeyword: (word) ->
    keywords.indexOf(word.toUpperCase()) isnt -1

  maybeParens: (it) -> if /\s/.exec it then "(#{it})" else it

  operator: (op) ->
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

class PostgresDialect extends BaseDialect
  {Select, Update, Delete, Insert} = require './nodes'

  render: (node) ->
    if node.constructor in [Select, Update, Delete, Insert]
      @paramCount = 1
    super node

  renderParameter: (node) ->
    "$#{@paramCount++}"
  operator: (op) ->
    switch op.toLowerCase()
      when 'hasKey' then '?'
      when '->' then '->'
      else super op

class MySQLDialect extends BaseDialect
  renderParameter: -> '?'

class SQLite3Dialect extends BaseDialect
  renderParameter: -> '?'

  renderInsertData: (node) ->
    if node.nodes.length < 2
      node.render(@, @path)
    else
      node.glue = ' UNION ALL SELECT '
      string = node.render(@, @path).replace('VALUES', 'SELECT').replace(/[()]/g, '')
      node.glue = ', '
      string

module.exports =
  base: BaseDialect
  postgres: PostgresDialect
  mysql: MySQLDialect
  sqlite3: SQLite3Dialect

