{SUDQuery, makeFrom} = require './sud-query'

module.exports = class Delete extends SUDQuery
	constructor: (table, opts={}) ->
		super table, opts
		@s.queryType = 'Delete'

Delete.from = -> new Delete arguments...
