vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

UPDATE = require('../lib').Update

vows.describe('UPDATE queries').addBatch(
	"When performing a DELETE": newQuery
		topic: -> UPDATE.table 't1'

		"and joining a second table": newQuery
			mod: -> @join "t2", on: {id: 't1.t2_id'}

			"and adding a condition": newQuery
				mod: -> @where age: {gt: 10}

		"and adding a limit": newQuery
			mod: -> @limit 10
			sql: "UPDATE t1 LIMIT 10"
			
			"and adding an order": newQuery
				mod: -> @orderBy age: 'DESC'
				sql: "UPDATE t1 ORDER BY t1.age DESC LIMIT 10"

).export(module)
