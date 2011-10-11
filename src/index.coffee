fluid = require './fluid'

sys = require 'sys'

unknown = (type, val) -> throw new Error "Unknown #{type}: #{val}"

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

dialects = exports.dialects =
	default: 'mysql'
	mysql: require './mysql'

passthrough_resolver =
	table: (n) -> n
	field: (n) -> n

exports.Query = class Query
	constructor: (opts) ->
		@dialect = opts.dialect || dialects.default
		@resolve = opts.resolver || passthrough_resolver
		@dialect = dialects[@dialect] if 'string' == typeof @dialect
		@s =
			includedTables: {}
			fields: {}
			tableStack: []
			where: []
			parameters: []
			raw_where: []

	clone: ->
		firstTable = @s.tableStack[0][0]
		child = new (@constructor)(firstTable)
		child.dialect = @dialect
		child.resolve = @resolve
		child.s = copy @s
		child

	pushTable: (table, alias, type, clause) ->
		if type != 'NOP'
			@s.includedTables[alias] = 1
			@s.fields[alias] ?= []
		@s.tableStack.push([table, alias, type, clause])

	lastTable: -> 
		@s.tableStack[@s.tableStack.length - 1][1]

	includesTable: (t) -> @s.includedTables[t]

	pushParams: (clauses) ->
		for clause in clauses
			if clause.op == 'multi'
				sys.puts "pushParam recursing" + clause.clauses
				@pushParams(clause.clauses)
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

exports.Select = class Select extends Query
	constructor: (tbl, opts={}) ->
		super opts
		@s.queryType = 'Select'
		@pushTable(tbl, tbl)

	# Switch to another table
	from: fluid (table) ->
		if @includesTable(table)
			@pushTable(table, table, 'NOP')
		else
			unknown 'table', table

	fields: fluid (fields...) -> 
		alias = @lastTable()
		for f in fields
			@s.fields[alias].push f

	field: @fields

	join: fluid (table, opts) ->
		opts ?= {}
		type = @dialect.joinType(opts.type)

		alias = table
		if @includesTable(table)
			unless opts.as?
				throw new Error "You must provide an alias when self-joining"
			alias = opts.as

		clause = opts.on
		if clause?
			clause = [clause] if clause.constructor != Array
			clause = normalize.clauses clause, alias, @dialect.joinOp

			if clause.length > 1
				clause = op: 'multi', glue: ' AND ', clauses: clause
			else
				clause = clause[0]

		@pushTable(table, alias, type, clause)
	
	where: fluid (tbl, clause) ->
		if not clause?
			clause = tbl
			tbl = @lastTable()

		unknown('table', tbl) unless @includesTable(tbl)?

		normalized = normalize.clauses [clause], tbl, @dialect.whereOp
		@s.where.push normalized...
		@pushParams normalized
	
	limit: fluid (l) -> @s.limit = l
	
	or: fluid (clauses...) ->
		tbl = @lastTable()
		normalized = normalize.clauses clauses, tbl, @dialect.whereOp
		@s.where.push op: 'multi', glue: ' OR ', clauses: normalized
		@pushParams normalized

exports.normalize = normalize =
	clauses: (clauses, table, normalizeOp) ->
		normalized = []
		for clause in clauses
			for fld, constraint of clause
				if 'object' == typeof constraint
					for op, val of constraint
						op = normalizeOp(op)
						normalized.push normalize.field_and_table
							field: fld, op: op, value: val, table: table
				else
					normalized.push normalize.field_and_table
						field: fld, op: '=', value: constraint, table: table
		return normalized

	# Check for dotted field names
	field_and_table: (normalized) ->
		[table, field] = normalized.field.split '.'
		if field?
			normalized.table = table
			normalized.field = field
		normalized

exports.from = (tbl, fields) -> 
	if tbl.constructor == Select
		throw new Error "Inner queries not supported yet"
	select = new Select(tbl)
	select.fields(fields...) if fields?
	return select
