###
Dialects are responsible for compiling an AST to a SQL string compatible with
a particular DBMS. They are rarely used directly, instead a query is usually
bound to an `engine <Engines>`_ that will delegate compiling to it's dialect
instance.
###

read = require('fs').readFileSync
kwFile = __dirname + '/sql_keywords.txt'
keywords = read(kwFile, 'ascii').split('\n').filter(Boolean)
{Select, Update, Delete, Insert, Relation, Field} = require './nodes'

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

    compile: (node) ->
      @path.push(node)
      name = node?.__proto__?.constructor?.name
      if name and custom = @dialect['render' + name]
        string = custom.call(@, node)
      else
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

class PostgresDialect extends BaseDialect
  operator: (op) ->
    switch op.toLowerCase()
      when 'hasKey' then '?'
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
  postgres: PostgresDialect
  mysql: MySQLDialect
  sqlite3: SQLite3Dialect

