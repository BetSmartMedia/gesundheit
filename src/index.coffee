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
	field: (t, n) -> n

exports.Query = class Query
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
			@s.fields[alias] ?= []
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

exports.Select = class Select extends Query
	constructor: (table, opts={}) ->
		super opts
		@s.queryType = 'Select'
		[table, alias] = @aliasPair table
		@pushTable(table, alias)

	# Switch to another table
	from: fluid (alias) ->
		if table = @includesAlias(alias)
			@pushTable(table, alias, 'NOP')
		else
			unknown 'table', table

	fields: fluid (fields...) -> 
		alias = unless fields[1] and fields[1].constructor == Array
			@lastTable()
		else
			first = fields.shift()
			unless @includesAlias first
				first = @resolve.table first
				unknown 'table', first unless @includesAlias first
			first

		for f in fields
			n = normalize.fieldAndTable table: alias, field: f
			field = @resolve.field n.table, n.field
			@s.fields[n.table].push field

	field: @fields

	join: fluid (tbl, opts={}) ->
		[table, alias] = @aliasPair tbl

		if @includesAlias(alias)
			throw new Error "Table alias is not unique: #{alias}"

		type = @dialect.joinType(opts.type)

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

		unknown('table', tbl) unless @includesAlias(tbl)?

		normalized = normalize.clauses [clause], tbl, @dialect.whereOp
		@s.where.push normalized...
		@pushParams normalized
	
	or: fluid (args...) ->
		clauses = normalize.clauses args, @lastTable(), @dialect.whereOp
		@s.where.push op: 'multi', glue: ' OR ', clauses: clauses
		@pushParams clauses

	orderBy: fluid (args...) ->
		orderings = normalize.orderings args, @lastTable(), @dialect.order
		@s.order.push orderings...

	groupBy: (fields...) ->
		groupings = for field in fields
			normalize.fieldAndTable table: @lastTable(), field: field
		@s.groupings.push groupings...

	limit: fluid (l) -> @s.limit = l
	
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
	fieldAndTable: (tableField) ->
		[table, field] = tableField.field.split '.'
		if field?
			tableField.table = table
			tableField.field = field
		tableField


exports.from = (tbl, fields, opts) ->
	if tbl.constructor == Select
		throw new Error "Inner queries not supported yet"
	if not opts? and fields? and fields.constructor != Array
		opts = fields
		fields = null
	select = new Select(tbl, opts)
	select.fields(fields...) if fields?
	return select
