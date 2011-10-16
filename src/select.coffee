fluid = require './fluid'
normalize = require './normalize'
{SUDQuery, makeFrom} = require './sud-query'

# Our friend the SELECT query. Select adds ORDER BY and GROUP BY support to SUDQuery.
module.exports = class Select extends SUDQuery
	constructor: (table, opts={}) ->
		super table, opts
		@s.queryType = 'Select'
		@s.groupings = []

# Add a GROUP BY to the query. Currently this *always* uses the last table added to the query.
	groupBy: (fields...) ->
		groupings = for field in fields
			normalize.fieldAndTable table: @lastTable(), field: field
		@s.groupings.push groupings...

Select.from = makeFrom(Select)
