fluid = require './fluid'

Query = require './base-query'

DEFAULT = require('./dialects/common').DEFAULT

# Inserts are much simpler than most query types, in that they cannot 
# join multiple tables.
module.exports = class Insert extends Query
	reset = (fn) ->
		(args...) ->
			@s.fields = []
			@s.parameters = []
			fn args...

	constructor: (table, opts={}) ->
		super opts
		@s.queryType = 'Insert'
		@s.table = @resolve.table table
		@s.fields = []
		@s.parameters = []

	fields: fluid (fields...) ->
		@s.fields = fields

	addRows: fluid (rows...) ->
		for row in rows
			if row.constructor == Array then @addRowArray row
			else @addRowObject row

	addRow: (row) -> @addRows row

	addRowArray: (row) ->
		count = @s.fields.length if @s.fields?
		throw new Error "Cannot insert from array without first setting fields" unless count
		if row.length != count
			throw new Error "Wrong number of values in array, expected #{@s.fields}"
		@s.parameters.push row...

	checkFields: (cb) ->

	addRowObject: (row) ->
		if not @s.fields or @s.fields.length == 0
			@s.fields = Object.keys row

		array = for f in @s.fields
			if row[f]? or row[f] == null then row[f] else DEFAULT
		@s.parameters.push array...


	fromQuery: fluid (query) ->
		@s.queryType = 'InsertSelect'
		@s.fromQuery = query

Insert.into = (tbl, opts) -> new Insert(tbl, opts)
