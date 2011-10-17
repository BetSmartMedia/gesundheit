fluid = require './fluid'
dialects = require './dialects'

# Query is the base class for all queries, it's not very useful on it's own,
# but it's important to understand the common functionality implemented by
# this class
module.exports = class Query
# Two options are common to all queries, a dialect and a resolver. The @s member
# contains all of the state specific to this query. It is what gets passed to 
# the render methods of the dialect, and what get's copied when .clone() is called.
	constructor: (opts) ->
		@dialect = opts.dialect || dialects.default
		@resolve = opts.resolver || passthrough_resolver
		if @dialect.pre?
			for method, checks of @dialect.pre
				for description, condition of checks
					#continue
					continue unless orig = @[method]
					do (method, description, orig, condition) =>
						@[method] = ->
							if condition.apply @s, arguments
								orig.apply @, arguments
							else
								throw new Error description
		@s = {}

# Instantiate a new query with a copy of the state that this one has. Useful for
# generating a bunch of similar queries in a loop or event handler
	clone: ->
		child = new @constructor
		child.dialect = @dialect
		child.resolve = @resolve
		child.s = copy @s
		child

# Call the given function in the context of this query. Makes for a sort-of DSL
# where you can do things like:
#     
#     somequery.visit ->
#       @where x: val
#       @orderBy x: 'ASC'
# 
# The current query is also given as the first parameter to the query, in case
# you need it.
	visit: fluid (fn) ->
		fn.call @, @ if fn?

# Pass the current query state to the appropriate render function of the dialect
	toSql: -> @dialect["render#{@s.queryType}"](@s)

# Given an object that exposes an `acquire` method, call the acquire method and 
# then continue with the result.
#
# Otherwise, call the `query` method of the object, passing it the SQL rendering
# of the query, the parameter values contained in the query, and the passed in 
# callback.
	execute: (conn, cb) ->
		if conn['acquire']? # Cheap hack to check for connection pools
			conn.acquire (c) => @execute c, cb
		else
			conn.query @toSql(), @s.parameters, cb

	toString: -> "[Query \"#{@toSql().substring(0,20)}\"]"

# The fallback resolver simply passes objects through untouched. Implement these
# these methods in your own resolver object to allow passing of arbitrary objects
# for table and field names.
passthrough_resolver =
	table: (t) -> t
	field: (t, f) -> f
	value: (t, f, v) -> v

# A deep-copy helper
copy = (thing) ->
	if thing == null then null
	else if thing.constructor == Array
		c = []
		c.push(thing...)
		return c
	else if 'object' == typeof thing
		obj = {}
		for k, v of thing
			obj[k] = copy(v)
		obj
	else thing

