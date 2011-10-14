common = require './common'
[JOIN_TYPES, DEFAULT] = ['JOIN_TYPES', 'DEFAULT'].map((k) -> common[k])

PLACEHOLDER = '?'
DEFAULT_JOIN = JOIN_TYPES.INNER


exports.renderSelect = (qs) ->
	"SELECT " + [
		fields, from, where, group, order, limit
	].map((f) -> f qs).join ''

# Returns the field list portion of a query
fields = (qs) ->
	fs = []
	for tbl, tbl_fields of qs.fields
		continue unless tbl_fields?
		if tbl_fields.length
			tbl_fields.forEach (f) ->
				fs.push "#{tbl}.#{f}"
		else
			fs.push "#{tbl}.*"
	fs.join ', '

# Returns the 'FROM' portion of a query
from = exports.from = (qs) ->
	i = 0
	tables = for [table, alias, type, clause] in qs.tableStack
		continue if type == 'NOP'

		ret = if i++ then "#{type.toUpperCase()} JOIN #{table}" else table

		if table != alias then ret += " AS #{alias}"
		if clause? then ret += " ON #{renderClause clause, (v) -> v}"
		ret
	' FROM ' + tables.join ' '

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
		when 'in' then 'IN'
		else throw new Error("Unsupported comparison operator: #{op}")

exports.joinType = (type) ->
	return 'INNER' unless type
	type = type.toUpperCase()
	if type in JOIN_TYPES then type
	else throw new Error "Unsupported JOIN type #{type}"

exports.renderInsert = (qs) ->
	"INSERT INTO #{qs.table} (#{qs.fields.join ', '}) VALUES #{renderInsertParams qs}"

renderInsertParams = (qs) ->
	rows = for [1 .. qs.parameters.length / qs.fields.length]
		renderBoundParam [1..qs.fields.length]
	rows.join ", "

exports.renderInsertSelect = (qs) ->
	"INSERT INTO #{table} #{qs.fromQuery.toSql()}"
