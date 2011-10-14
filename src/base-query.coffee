fluid = require './fluid'

passthrough_resolver =
	table: (n) -> n
	field: (t, n) -> n

dialects = require './dialects'

copy = (thing) ->
	if thing.constructor == Array
		c = []
		c.push(thing...)
		return c
	else if 'object' == typeof thing
		obj = {}
		for k, v of thing
			obj[k] = copy(v)
		obj
	else thing

module.exports = class Query
	constructor: (opts) ->
		@dialect = opts.dialect || dialects.default
		@resolve = opts.resolver || passthrough_resolver
		@dialect = dialects[@dialect] if 'string' == typeof @dialect
		@s = {}

	clone: ->
		firstTable = @s.tableStack[0][0]
		child = new (@constructor)(firstTable)
		child.dialect = @dialect
		child.resolve = @resolve
		child.s = copy @s
		child

	visit: fluid (fn) ->
		fn.call @, @ if fn?

	toSql: -> @dialect["render#{@s.queryType}"](@s)

	toString: -> "[Query \"#{@toSql().substring(0,20)}\"]"

	execute: (conn, cb) ->
		if conn['acquire']? # Cheap hack to check for connection pools
			conn.acquire (c) => @execute c, cb
		else
			conn.query @toSql(), @s.parameters, cb

