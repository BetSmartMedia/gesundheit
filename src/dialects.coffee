###
Dialects are responsible for compiling an AST to a SQL string compatible with
a particular DBMS. They are rarely used directly, instead a query is usually
bound to an `engine <Engines>`_ that will delegate compiling to it's dialect
instance.
###

{Select, Update, Delete, Insert, Relation, Field} = require './nodes'

if process.browser
  keywords = []
else
  keywords = require('fs')
    .readFileSync(__dirname + '/sql_keywords.txt')
    .toString()
    .split('\n').filter(Boolean)

class BaseDialect

  reset: ->

  compile: (root) ->
    visitor = new Visitor(@)
    text = visitor.compile(root)
    [text, visitor.params]

  renderString: (s) ->
    path = @path.map((p) -> p.constructor?.name).join(' > ')
    @path = []
    throw new Error "raw string compiled! " + path

  needsQuote = /\s|"|\./
  doubleQuote = /"/g

  quote: (s) ->
    if s?.match(needsQuote) or @isKeyword(s)
      '"' + s.replace(doubleQuote, '\\"') + '"'
    else
      s

  isKeyword: (word) ->
    keywords.indexOf(word.toUpperCase()) isnt -1

  operator: (op) ->
    switch (op = op.toUpperCase())
      when 'NE', '!=', '<>' then '!='
      when 'EQ', '='   then '='
      when 'LT', '<'   then '<'
      when 'GT', '>'   then '>'
      when 'LTE', '<=' then '<='
      when 'GTE', '>=' then '>='
      when 'LIKE', 'ILIKE', 'IN', 'NOT IN', 'IS', 'IS NOT' then op
      else throw new Error("Unsupported comparison operator: #{op}")

  placeholder: (position) ->
    "$#{position}"

  class Visitor
    constructor: (@dialect) ->
      @path   = []
      @params = []

    compile: (node, allowOverride=true) ->
      @path.push(node)
      name = node?.__proto__?.constructor?.name
      if allowOverride and name and custom = @dialect['render' + name]
        string = custom.call(@, node)
      else
        debugger unless node?.compile
        string = node.compile(@, @path)
      @path.pop(node)
      return string

    maybeParens: (it) -> if /\s/.exec it then "(#{it})" else it

    operator: (string) ->
      @dialect.operator(string)

    parameter: (val) ->
      @params.push val
      @dialect.placeholder(@params.length)

    quote: (string) ->
      @dialect.quote(string, @path)

class PrettyDialect extends BaseDialect
  renderJoin:        (node) -> "\n" + @compile(node, false)
  renderWhere:       (node) -> "\n" + @compile(node, false)
  renderHaving:      (node) -> "\n" + @compile(node, false)
  renderOrderBy:     (node) -> "\n" + @compile(node, false)
  renderGroupBy:     (node) -> "\n" + @compile(node, false)
  renderRelationSet: (node) -> "\n" + @compile(node, false)
  renderSelectColumnSet: (node) ->
    glue           = node.glue
    last           = node.nodes.length
    lines          = []
    thisLine       = []
    thisLineLength = 81
    for node in node.nodes
      text = @compile(node)
      size = text.length + glue.length
      if thisLineLength + size > 50
        lines.push(thisLine.join(glue))
        thisLine = []
        thisLineLength = 0
      thisLineLength += size
      thisLine.push text
    lines.shift()
    lines.push(thisLine.join(glue))
    lines.join("\n  ")


class PostgresDialect extends BaseDialect
  operator: (op) ->
    switch op.toLowerCase()
      when 'hasKey', '?' then '?'
      when 'contains', '@>' then '@>'
      when '->' then '->'
      else super op

  isKeyword: (s) -> s? and s isnt '*'

class MySQLDialect extends BaseDialect
  placeholder: -> '?'

  quote: (s, path) ->
    ###
    MySQL has two special cases for quoting:
     - The column names in an insert column list are not quoted
     - table and field names are quoted with backticks.
    ###
    node = path[path.length - 1]
    if s is '*' or path.some((node) -> node instanceof Insert.ColumnList)
      s
    else if node instanceof Field or node instanceof Relation
      "`#{s}`"
    else
      super


class SQLite3Dialect extends BaseDialect
  placeholder: -> '?'

  renderInsertData: (node) ->
    if node.nodes.length < 2
      node.compile(@, @path)
    else
      node.glue = ' UNION ALL SELECT '
      string = node.compile(@, @path)
        .replace('VALUES', 'SELECT')
        .replace(/[()]/g, '')
      node.glue = ', '
      string

module.exports =
  base: BaseDialect
  pretty: PrettyDialect
  postgres: PostgresDialect
  mysql: MySQLDialect
  sqlite3: SQLite3Dialect

