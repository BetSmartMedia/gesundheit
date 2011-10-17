fluid = require './fluid'
normalize = require './normalize'
{SUDQuery, makeFrom} = require './sud-query'

# Our friend the SELECT query. Select adds ORDER BY and GROUP BY support to SUDQuery.
module.exports = class Select extends SUDQuery
	constructor: (table, opts={}) ->
		super table, opts
		@s.queryType = 'Select'
		@s.fields = {}
		@s.groupings = []
		if table?
			[table, alias] = @aliasPair table
			@s.fields[alias] = []

# Adds one or more fields to the query. If the second argument is an array, the first argument
# is treated as a table (in the same way that `join` understands tables) and the second argument
# as the list of fields to select/update from that table. The table must already be joined for
# this to work.
#
# If the second argument is not an array, then each argument is treated as an individual field of
# the last table added to the query.

	fields: fluid (fields...) ->
		alias = unless fields[1] and fields[1].constructor == Array
			@lastAlias()
		else
			[table, al] = @aliasPair fields.shift()
			unknown 'table', table unless @includesAlias al

		if fields.length == 0
			return @s.fields[alias] = null

# The fields support aliasing in the same way that tables do, an object with 
# one key will be treated as an alias -> fieldName pair. The fieldName will be
# resolved via the resolver before being pushed onto the list of fields
		for f in fields
			aliased = typeof f == 'object' and Object.keys(f).length == 1
			[fieldName, fieldAlias] = if not aliased then [f, f]
			else ([fn, fa] for fa, fn of f)[0]

			fieldName = @resolve.field alias, fieldName
			fieldAlias = fieldName if not aliased
			@s.fields[alias] ?= []
			@s.fields[alias].push [fieldName, fieldAlias]

# A nice shorthand for adding a single field
	field: (f...) -> @fields f...

# Add a GROUP BY to the query. Currently this *always* uses the last table added to the query.
	groupBy: (fields...) ->
		alias = @lastAlias()
		groupings = for field in fields
			{table: alias, field: field}

		@s.groupings.push groupings...

Select.from = (tbl, fields, opts) ->
	if tbl instanceof Select
		throw new Error "Inner queries not supported yet"
	if fields? and fields.constructor != Array
		opts = fields
		fields = null
	query = new Select(tbl, opts)
	if fields?
		query.fields fields...
	return query

