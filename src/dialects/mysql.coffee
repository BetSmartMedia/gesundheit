common = require './common'
[JOIN_TYPES, DEFAULT] = ['JOIN_TYPES', 'DEFAULT'].map((k) -> common[k])

PLACEHOLDER = '?'
DEFAULT_JOIN = JOIN_TYPES.INNER


exports.pre =
	orderBy:
		"ORDER BY with multiple tables is only allowed for SELECT": ->
			@queryType == 'Select' or @tableStack.length == 1

	limit:
		"LIMIT with multiple tables is only allowed for SELECT": ->
			@queryType == 'Select' or @tableStack.length == 1
			
	join:
		"JOIN with ORDER BY or LIMIT is only allowed for SELECT": ->
			@queryType == 'Select' or (@order.length == 0 and not @limit)


exports.renderSelect = (qs) ->
	"SELECT #{fields(qs)} FROM " + [
		tables, where, group, order, limit
	].map((f) -> f qs).join ''

exports.renderUpdate = (qs) ->
	parts = if qs.tableStack.length == 1
		[tables, set, where, order, limit]
	else
		[tables, set, where]

	"UPDATE " + parts.map((f) -> f(qs)).join ''

set = (qs) ->
	' SET ' + qs.fields.map((f) -> if f.match /\=/ then f else "#{f} = ?").join ', '

exports.renderInsert = (qs) ->
	"INSERT INTO #{qs.table} (#{qs.fields.join ', '}) VALUES #{renderInsertParams qs}"

exports.renderInsertSelect = (qs) ->
	"INSERT INTO #{qs.table} #{qs.fromQuery.toSql()}"

exports.renderDelete = (qs) ->
	parts = if qs.tableStack.length == 1
		[tables, where, order, limit]
	else
		[tables, where]

	"DELETE FROM " + parts.map((f) -> f(qs)).join ''
# Returns the field list portion of a query
fields = (qs) ->
	fs = []
	for tbl, tbl_fields of qs.fields
		continue unless tbl_fields?
		if tbl_fields.length
			for f in tbl_fields
				fs.push if f[0] == f[1] then "#{tbl}.#{f[0]}" else "#{tbl}.#{f[0]} AS '#{f[1]}'"
		else
			fs.push "#{tbl}.*"
	fs.join ', '

# Returns the 'FROM' portion of a query
tables = exports.tables = (qs) ->
	i = 0
	ts = for [table, alias, type, clause] in qs.tableStack
		continue if type == 'NOP'

		ret = if i++ then "#{type.toUpperCase()} JOIN #{table}" else table

		if table != alias then ret += " AS #{alias}"
		if clause? then ret += " ON #{renderClause clause, (v) -> v}"
		ret
	ts.join ' '

# Returns the 'WHERE' portion of a query
where = exports.where = (qs) ->
	if qs.where.length then " WHERE #{renderClause qs.where}" else ""

# Returns the 'GROUP BY' portion of a query
group = exports.group = (qs) ->
	if qs.groupings.length
		" GROUP BY #{qs.groupings.map((g) -> g.table+'.'+g.field).join ', '}"
	else ""

# Returns the 'ORDER BY' portion of a query
order = exports.order = (qs) ->
	if qs.order.length
		" ORDER BY #{qs.order.map((o) ->
			o.table+'.'+o.field + if o.direction then ' '+o.direction else ''
		).join ', '}"
	else ""

# Returns the 'LIMIT' portion of a query
# TODO - parseInt
limit = (qs) -> if qs.limit? then " LIMIT #{qs.limit}" else ""

# Given a query parameter, returns a `PLACEHOLDER`. Given an array as the parameter, renders
# a list of `PLACEHOLDER` tokens equal in length to the array.
renderBoundParam = (v) ->
	if v and v.constructor == Array then "(#{v.map(-> PLACEHOLDER).join ', '})"
	else PLACEHOLDER

# Renders an individual query clause
exports.renderClause = renderClause = (input, renderValue=renderBoundParam) ->
	render = (clause) ->
		if clause? and clause.constructor == Array
			"#{clause.map(render).join(' AND ')}"
		else if typeof clause == 'object'
			if clause.op == 'multi'
				"(#{clause.clauses.map(render).join(clause.glue)})"
			else
				"#{clause.table}.#{clause.field} #{clause.op} #{renderValue clause.value}"
		else
			throw new Error "Unexpected clause type, this is probably a bug"
	render input

# TODO - check whether there is any difference in the supported comparison operators
exports.joinOp = exports.whereOp = (op) ->
	switch op.toLowerCase()
		when 'ne', '!=', '<>' then '!='
		when 'eq', '='   then '='
		when 'lt', '<'   then '<'
		when 'gt', '>'   then '>'
		when 'lte', '<=' then '<='
		when 'gte', '>=' then '>='
		when 'like' then 'LIKE'
		when 'in' then 'IN'
		else throw new Error("Unsupported comparison operator: #{op}")

exports.joinType = (type) ->
	return 'INNER' unless type
	type = type.toUpperCase()
	if type in JOIN_TYPES then type
	else throw new Error "Unsupported JOIN type #{type}"

renderInsertParams = (qs) ->
	offset = 0
	rowLength = qs.fields.length
	paramLength = qs.parameters.length
	rows = while offset < paramLength
		params = for p in qs.parameters[offset ... (offset+rowLength)]
			if p == DEFAULT then 'DEFAULT' else PLACEHOLDER
		offset += rowLength
		"(#{params.join ', '})"
	rows.join ", "
