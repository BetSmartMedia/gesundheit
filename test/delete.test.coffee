vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

DELETE = require('../lib').Delete

vows.describe('DELETE queries').addBatch(
	"When performing a DELETE": newQuery
		topic: -> DELETE.from 't1'
		sql: "DELETE FROM t1"

		"and joining a second table": newQuery
			mod: -> @join "t2", on: {id: 't1.t2_id'}
			sql: "DELETE FROM t1 INNER JOIN t2 ON t2.id = t1.t2_id"

			"and adding a condition": newQuery
				mod: -> @where age: {gt: 10}
				sql: "DELETE FROM t1 INNER JOIN t2 ON t2.id = t1.t2_id WHERE t2.age > ?"

		"and adding a limit": newQuery
			mod: -> @limit 10
			sql: "DELETE FROM t1 LIMIT 10"
			
			"and adding an order": newQuery
				mod: -> @orderBy age: 'DESC'
				sql: "DELETE FROM t1 ORDER BY t1.age DESC LIMIT 10"

).export(module)
