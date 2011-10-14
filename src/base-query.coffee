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
		@s =
			includedAliases: {}
			fields: {}
			tableStack: []
			where: []
			order: []
			groupings: []
			parameters: []
			raw_where: []

	clone: ->
		firstTable = @s.tableStack[0][0]
		child = new (@constructor)(firstTable)
		child.dialect = @dialect
		child.resolve = @resolve
		child.s = copy @s
		child

	aliasPair: (table) ->
		if 'object' == typeof table and Object.keys(table).length == 1
			([@resolve.table(t), a] for a, t of table)[0]
		else
			t = @resolve.table(table)
			[t, t]

	pushTable: (table, alias, type, clause) ->
		if table == "t1t1" then throw new Error "here"
		if type != 'NOP'
			@s.includedAliases[alias] = table
		@s.tableStack.push([table, alias, type, clause])

	lastTable: -> 
		@s.tableStack[@s.tableStack.length - 1][1]

	includesAlias: (a) -> @s.includedAliases[a]

	pushParams: (clauses) ->
		for clause in clauses
			if clause.op == 'multi'
				sys.puts "pushParam recursing" + clause.clauses
				@pushParams(clause.clauses)
			else if clause.op == 'IN'
				@s.parameters.push clause.value...
			else
				@s.parameters.push clause.value

	visit: fluid (fn) ->
		fn.call @, @ if fn?

	toSql: -> @dialect["render#{@s.queryType}"](@s)

	toString: -> "[Query \"#{@toSql().substring(0,20)}\"]"

	execute: (conn, cb) ->
		if conn['acquire']? # Cheap hack to check for connection pools
			conn.acquire (c) => @execute c, cb
		else
			conn.query @toSql(), @s.parameters, cb

