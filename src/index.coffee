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
			order: []
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

		alias = opts.as || table
		if @includesTable(alias)
			throw new Error "Table alias is not unique: #{alias}"

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
	
	or: fluid (args...) ->
		clauses = normalize.clauses args, @lastTable(), @dialect.whereOp
		@s.where.push op: 'multi', glue: ' OR ', clauses: clauses
		@pushParams clauses

	orderBy: fluid (args...) ->
		orderings = normalize.orderings args, @lastTable(), @dialect.order
		@s.order.push orderings...

exports.normalize = normalize =
	clauses: (clauses, table, normalizeOp) ->
		normalized = []
		for clause in clauses
			for fld, constraint of clause
				if 'object' == typeof constraint
					for op, val of constraint
						op = normalizeOp(op)
						normalized.push normalize.fieldAndTable
							field: fld, op: op, value: val, table: table
				else
					normalized.push normalize.fieldAndTable
						field: fld, op: '=', value: constraint, table: table
		return normalized

	orderings: (orderings, table) ->
		normalized = []
		add = (field, direction) ->
			direction = switch (direction || '').toLowerCase()
				when 'asc',  'ascending'  then 'ASC'
				when 'desc', 'descending' then 'DESC'
				when '' then ''
				else throw new Error "Unsupported ordering direction #{direction}"
			normalized.push normalize.fieldAndTable
				field: field, table: table, direction: direction

		for ordering in orderings
			if 'string' == typeof ordering
				[field, direction] = ordering.split /\ +/ 
				add field, direction
			else for field, direction of ordering
				add field, direction

		return normalized

	# Check for dotted field names
	fieldAndTable: (normalized) ->
		[table, field] = normalized.field.split '.'
		if field?
			normalized.table = table
			normalized.field = field
		normalized


exports.from = (tbl, fields, opts) ->
	if tbl.constructor == Select
		throw new Error "Inner queries not supported yet"
	if not opts? and fields? and fields.constructor != Array
		opts = fields
		fields = null
	select = new Select(tbl, opts)
	select.fields(fields...) if fields?
	return select
