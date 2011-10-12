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
	"SELECT #{fieldList(qs)} FROM #{joins(qs)}#{where(qs)}#{order(qs)}#{limit(qs)}"

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
	ret = qs.tableStack[0][0]
	clauses = []
	for [table, alias, type, clause] in qs.tableStack[1..-1]
		continue if type == 'NOP'
		ret += " #{type.toUpperCase()} JOIN #{table}"
		if table != alias
			ret += " AS #{alias}"
		clauses.push clause if clause?

	if clauses.length then ret += " ON #{renderClause clauses, (v) -> v}"
	ret

where = exports.where = (qs) ->
	if qs.where.length then " WHERE #{renderClause qs.where}" else ""

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

exports.renderClause = renderClause = (input, renderValue) ->
	renderValue ?= renderBoundParam
	render = (clause) ->
		if clause.constructor == Array
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

