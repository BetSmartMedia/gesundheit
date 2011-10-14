fluid = require './fluid'
SUDQuery = require './sud-query'
normalize = require './normalize'

# Our friend the SELECT query. Select adds ORDER BY and GROUP BY support to SUDQuery.
module.exports = class Select extends SUDQuery
	constructor: (table, opts={}) ->
		super opts
		@s.queryType = 'Select'
		@s.order = []
		@s.groupings = []

# Add an ORDER BY to the query. Currently this *always* uses the last table added to the query.
#
# Each ordering can either be a string, in which case it must be a valid-ish SQL snippet 
# like 'some_field DESC', (the field name and direction will still be normalized) or an object, 
# in which case each key will be treated as a field and each value as a direction.
	orderBy: fluid (args...) ->
		orderings = normalize.orderings args, @lastTable(), @dialect.order
		@s.order.push orderings...

# Add a GROUP BY to the query. Currently this *always* uses the last table added to the query.
	groupBy: (fields...) ->
		groupings = for field in fields
			normalize.fieldAndTable table: @lastTable(), field: field
		@s.groupings.push groupings...

# You can guess what this does ;)
	limit: fluid (l) -> @s.limit = l
	
# A more sugary way of constructing new select queries
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
