fluid = require './fluid'

unknown = (type, val) -> throw new Error "Unknown #{type}: #{val}"

Query = require './base-query'

module.exports = class Select extends Query
	constructor: (table, opts={}) ->
		super opts
		@s.queryType = 'Select'
		[table, alias] = @aliasPair table
		@pushTable(table, alias)
		@s.fields[alias] = []

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
			a = fields.shift()
			if @includesAlias a then a else
				a = @resolve.table a
				unknown 'table', a unless @includesAlias a
				a

		if fields.length == 0
			return @s.fields[alias] = null
		
		for f in fields
			n = normalize.fieldAndTable table: alias, field: f
			field = @resolve.field n.table, n.field
			@s.fields[n.table] ?= []
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


Select.from = (tbl, fields, opts) ->
	if tbl.constructor == Select
		throw new Error "Inner queries not supported yet"
	if fields? and fields.constructor not in [String, Array]
		opts = fields
		fields = null
	select = new Select(tbl, opts)
	if fields?
		switch fields.constructor
			when String then select.fields fields
			when Array  then select.fields fields...
	return select
