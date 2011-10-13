sys = require 'sys'

AND = ' AND '
OR = ' OR '
JOIN_TYPES = [
	'INNER', 'CROSS',       'FULL OUTER',
	'LEFT',  'LEFT INNER',  'LEFT OUTER',
	'RIGHT', 'RIGHT INNER', 'RIGHT OUTER',
]

QUOTED  = 'quoted'
LITERAL = 'literal'
BOUND_PARAM = '?'

DEFAULT_JOIN = "INNER"

exports.renderSelect = (qs) ->
	ret = "SELECT #{fieldList(qs)} FROM "
	ret += joins(qs)
	ret += where(qs)
	ret += group(qs)
	ret += order(qs)
	ret += limit(qs)

fieldList = (qs) ->
	fields = []
	for tbl, tbl_fields of qs.fields
		if tbl_fields.length
			tbl_fields.forEach (f) ->
				fields.push "#{tbl}.#{f}"
		else
			fields.push "#{tbl}.*"
	fields.join ', '

joins = exports.joins = (qs) ->
	i = 0
	tables = for [table, alias, type, clause] in qs.tableStack
		continue if type == 'NOP'

		ret = if i++ then "#{type.toUpperCase()} JOIN #{table}" else table

		if table != alias then ret += " AS #{alias}"
		if clause? then ret += " ON #{renderClause clause, (v) -> v}"
		ret
	tables.join ' '

where = exports.where = (qs) ->
	if qs.where.length then " WHERE #{renderClause qs.where}" else ""

group = exports.group = (qs) ->
	if qs.groupings.length
		" GROUP BY #{qs.groupings.map((g) -> g.table+'.'+g.field).join ', '}"
	else ""

order = exports.order = (qs) -> 
	if qs.order.length
		' ORDER BY ' + qs.order.map((o) -> 
			o.table+'.'+o.field + if o.direction then ' '+o.direction else ''
		).join ', '
	else ""

# TODO - parseInt
limit = (qs) -> if qs.limit? then " LIMIT #{qs.limit}" else ""

renderBoundParam = (v) ->
	if v and v.constructor == Array then "(#{v.map(-> BOUND_PARAM).join ', '})"
	else BOUND_PARAM

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
		when 'in' then 'IN'
		else throw new Error("Unsupported comparison operator: #{op}")

exports.joinType = (type) ->
	return DEFAULT_JOIN unless type?
	type = type.toUpperCase()
	return type if type in JOIN_TYPES
	throw new Error "Unsupported join type: #{type}"

