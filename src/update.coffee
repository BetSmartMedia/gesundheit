fluid = require './fluid'
{SUDQuery, makeFrom} = require './sud-query'

module.exports = class Update extends SUDQuery
	constructor: (table, opts={}) ->
		super table, opts
		@s.table = table
		@s.queryType = 'Update'
		@s.fields = []

	set: fluid (data) ->
		table = @s.table
		for field, value of data
			field = @resolve.field table, field
			value = @resolve.value table, field, value
			@s.fields.push field
			@s.parameters.push value

	setRaw: fluid (data) ->
		for field, value of data
			@s.fields.push field+'='+data

	toSql: ->
		throw new Error "Cannot render UPDATE without setting columns" unless @s.fields.length
		super()


Update.table = -> new Update arguments...
