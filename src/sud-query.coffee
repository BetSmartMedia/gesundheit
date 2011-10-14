# SUDQuery is the base class for SELECT, UPDATE, and DELETE queries. It adds logic to `Query` for
# dealing with joins, table aliases, and WHERE clauses.
fluid = require './fluid'
Query = require './base-query'
normalize = require './normalize'

# It is organized into two major groups of methods. The first group makes up the more "public" interface to the query. These methods mostly correspond to their SQL analogs; i.e. join(...) joins another table. The second group is made up of helper methods for safely managing the stateful data structures added to the @s member in the constructor.
module.exports = class SUDQuery extends Query
	constructor: (table, opts) ->
		super opts
		@s.fields = {}
		@s.includedAliases = {}
		@s.tableStack = []
		@s.where = []
		@s.parameters = []
		if table?
			[table, alias] = @aliasPair table
			@s.fields[alias] = []
			@pushTable(table, alias)

# Adds one or more fields to the query. If the second argument is an array, the first argument
# is treated as a table (in the same way that `join` understands tables) and the second argument
# as the list of fields to select/update from that table. The table must already be joined for 
# this to work.
#
# If the second argument is not an array, then each argument is treated as an individual field of
# the last table added to the query.
#
# In any case, fields are always normalized via `normalize.fieldAndTable`

	fields: fluid (fields...) ->
		alias = unless fields[1] and fields[1].constructor == Array
			@lastTable()
		else
			[table, al] = @aliasPair fields.shift()
			unknown 'table', table unless @includesAlias al

		if fields.length == 0
			return @s.fields[alias] = null
		
		for f in fields
			n = normalize.fieldAndTable table: alias, field: f
			field = @resolve.field n.table, n.field
			@s.fields[n.table] ?= []
			@s.fields[n.table].push field

# A nice shorthand for adding a single field
	field: @fields

# Join takes a table and an object of options:
#
# - `on`: An object or array of objects describing the ON ... part of the join clause.
#   Each key is treated as a field name of the table being joined, while each value is any
#   valid comparison operator (see `where` for more). Passing an array will cause the
#   conditions to be AND'ed together
#
# - `fields`: A list of fields that will be selected/updated from this table. (Optional, you can
#   always add fields with `fields`)
#
# The table parameter can be any object that
# your resolver can turn into a string table name. However, there is a special case for objects
# with a single key: the key is treated as an alias, and the value is passed to the resolver to
# determine the table name.

	join: fluid (tbl, opts={}) ->
		[table, alias] = @aliasPair tbl

		if @includesAlias(alias)
			throw new Error "Table alias is not unique: #{alias}"

		type = @dialect.joinType(opts.type)

		if (clause = opts.on)?
			clause = [clause] if clause.constructor != Array
			clause = normalize.clauses clause, alias, @dialect.joinOp

			if clause.length > 1
				clause = op: 'multi', glue: ' AND ', clauses: clause
			else
				clause = clause[0]

		@pushTable(table, alias, type, clause)
		if opts.fields?
			@fields(opts.fields...)
	
# Make a different table "active", this will use that table as the default for fields/where
	from: fluid (alias) ->
		if table = @includesAlias(alias)
			@pushTable(table, alias, 'NOP')
		else
			unknown 'table', table

# Add a WHERE clause to the query. Can optionally take a table/alias name as the first
# parameter, otherwise the clause is added using the last table added to the query.
#
# The where clause itself is an object where each key is treated as field name and each value is
# treated as a constraint. Constraints can be literal values or objects, in which case each key of the constraint is treated as an operator, and each value must be a literal value. Supported
# operators are determined by the dialect of the query. See dialect/mysql.coffee for an example.
	where: fluid (alias, clause) ->
		if not clause?
			clause = alias
			alias = @lastTable()
		else
			[table, alias] = @aliasPair alias

		unknown('table', tbl) unless @includesAlias(alias)?

		normalized = normalize.clauses [clause], alias, @dialect.whereOp
		@s.where.push normalized...
		@pushParams normalized
	
# Add one or more WHERE clauses, all joined by the OR operator
	or: fluid (args...) ->
		clauses = normalize.clauses args, @lastTable(), @dialect.whereOp
		@s.where.push op: 'multi', glue: ' OR ', clauses: clauses
		@pushParams clauses

# This group of methods is concerned with managing the stateful data structures
# created by the constructor. There should rarely be a need to call these from outside the Query
# objects themselves.
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
		@s.tableStack.push([table, alias, type, clause])

	pushParams: (clauses) ->
		for clause in clauses
			if clause.op == 'multi'
				sys.puts "pushParam recursing" + clause.clauses
				@pushParams(clause.clauses)
			else if clause.op == 'IN'
				@s.parameters.push clause.value...
			else
				@s.parameters.push clause.value

	lastTable: ->
		@s.tableStack[@s.tableStack.length - 1][1]

	includesAlias: (a) -> @s.includedAliases[a]

# A helper for throwing Errors
unknown = (type, val) -> throw new Error "Unknown #{type}: #{val}"
