fluid = require './fluid'
SUDQuery = require './sud-query'
{Update, Binary, Parameter} = require './nodes'

module.exports = class UpdateQuery extends SUDQuery
	set: fluid (data) ->
		for field, value of data
			@q.updates.addNode new Binary field, '=', new Parameter value

	setNodes: fluid (nodes...) -> @q.updates.push nodes...

	setRaw: fluid (data) ->
		for field, value of data
			@q.fields.push field+' = '+value

	defaultRel: -> @q.relation

UpdateQuery.table = (table, opts={}) ->
	opts.table = table
	new UpdateQuery Update, opts
