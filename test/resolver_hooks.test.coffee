vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

select = require('../lib').select

resolver =
	table: (t) -> t.split('_').map((s) -> s[0].toUpperCase() + s[1..-1]).join ''
	field: (table, field) -> field.toUpperCase()
	test: true # Marks this for debugging in the test below

suite = vows.describe('Custom resolvers').addBatch(
	"When doing a SELECT with a custom resolver": newQuery
		topic: -> select.from 'the_table', resolver: resolver
		msg: "The table name is resolved"
		sql: "SELECT TheTable.* FROM TheTable"

		"the resolver is set on the query": (q) -> assert.equal q.resolve, resolver

		"and adding fields": newQuery
			mod: -> @fields "height", "width"
			msg: "The field names are resolved"
			sql: "SELECT TheTable.HEIGHT, TheTable.WIDTH FROM TheTable"

		"and adding stringy fields": newQuery
			mod: -> @fields "height", "width"
			msg: "The field and table names are resolved"

	"When doing a SELECT with a custom resolver and fields": newQuery
		topic: -> select.from 'the_table', ["height", "width"], resolver: resolver
		msg: "The table name and field names are resolved"
		sql: "SELECT TheTable.HEIGHT, TheTable.WIDTH FROM TheTable"

	"When doing a SELECT with an aliased table, custom resolver, and fields": newQuery
		topic: -> select.from tt: 'the_table', ["height", "width"], resolver: resolver
		msg: "The table name and field names are resolved"
		sql: "SELECT tt.HEIGHT, tt.WIDTH FROM TheTable AS tt"

).export(module)
