vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

UPDATE = require('../lib').Update

vows.describe('UPDATE queries').addBatch(
	"When performing an UPDATE": newQuery
		topic: -> UPDATE.table 't1'

		"converting to sql fails": (q) ->
			assert.throws (-> q.toSql()), Error

		"and setting a column to a value": newQuery
			mod: -> @set x: 45
			sql: "UPDATE t1 SET x = ?"
			par: [45]

			"and adding a condition": newQuery
				mod: -> @where x: 44
				sql: "UPDATE t1 SET x = ? WHERE t1.x = ?"
				par: [45, 44]

			"and adding a condition on a joined table"
				mod: -> @join("t2", on: {id: 't1.t2_id'}).where z: 22
				sql: "UPDATE t1 INNER JOIN t2 ON t2.id = t1.t2_id SET x = ? WHERE t2.z = ?"

			"and adding a limit": newQuery
				mod: -> @limit 10
				sql: "UPDATE t1 SET x= ? WHERE t1.x = ? LIMIT 10"
			
				"and adding an order": newQuery
					mod: -> @orderBy age: 'DESC'
					sql: "UPDATE t1 SET x= ? ORDER BY t1.age DESC LIMIT 10"
).export(module)
