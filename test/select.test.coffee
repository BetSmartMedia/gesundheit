vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

select = require('../lib').Select

suite = vows.describe('SELECT queries').addBatch(
	"When performing a SELECT": newQuery
		topic: -> select.from 't1'
		sql: "SELECT t1.* FROM t1"

		"self-joins require alias": (q) ->
			assert.throws((-> q.join("t1")), Error)
		
		"and executing it":
			topic: (q) ->
				fakeClient =
					query: (sql, par, cb) ->
						assert.equal sql, 'SELECT t1.* FROM t1'
						assert.deepEqual par, []
						cb null, "Sweet"
				q.execute fakeClient, @callback

			"the callback gets the result": (res) -> assert.equal("Sweet", res)

		"and setting a limit": newQuery
			mod: -> @limit 100
			sql: "SELECT t1.* FROM t1 LIMIT 100"

		"and adding an ORDER BY": newQuery
			mod: -> @orderBy size: 'ASC'
			sql: "SELECT t1.* FROM t1 ORDER BY t1.size ASC"

		"and adding a string ORDER BY": newQuery
			mod: -> @orderBy 'size'
			sql: "SELECT t1.* FROM t1 ORDER BY t1.size"

		"and adding a string ORDER BY with a direction": newQuery
			mod: -> @orderBy 'size descending'
			sql: "SELECT t1.* FROM t1 ORDER BY t1.size DESC"

		"and a where clause is added": newQuery
			mod: -> @where x: 2
			sql: "SELECT t1.* FROM t1 WHERE t1.x = ?",
			par: [ 2 ]

		"and a 'lt' where clause is added": newQuery
			mod: -> @where x: {lt: 10}
			sql: "SELECT t1.* FROM t1 WHERE t1.x < ?"
			par: [ 10 ]

		"and an 'OR' where clause is added": newQuery
			mod: -> @or x: {lt: 10}, y: 10
			sql: "SELECT t1.* FROM t1 WHERE (t1.x < ? OR t1.y = ?)"
			par: [10, 10]
		
		"and an 'IN' where clause is added": newQuery
			mod: -> @where x: {in: [1,2,3]}
			sql: "SELECT t1.* FROM t1 WHERE t1.x IN (?, ?, ?)"
			par: [1, 2, 3]

		"and joining another table": newQuery
			mod: -> @join "t2"
			sql: "SELECT t1.* FROM t1 INNER JOIN t2"

			"switching to an unjoined table throws an Error": (q) ->
				assert.throws((-> q.table("blah")), Error)

			"and fields are added": newQuery
				mod: -> @fields("b")
				msg: "fields are added to the second table"
				sql: "SELECT t1.*, t2.b FROM t1 INNER JOIN t2"

			"and fields are added on the first table": newQuery
				mod: -> @from("t1").fields "a", "b"
				sql: "SELECT t1.a, t1.b FROM t1 INNER JOIN t2"

		"and joining another table using a clause": newQuery
			mod: -> @join "t2", on: {x: 't1.y'}
			sql: "SELECT t1.* FROM t1 INNER JOIN t2 ON t2.x = t1.y"

		"and joining another table using a clause with multiple conditions": newQuery
			mod: -> @join "t2", on: {x: 't1.x', y: 't1.y'}
			sql: "SELECT t1.* FROM t1 INNER JOIN t2 ON (t2.x = t1.x AND t2.y = t1.y)"

		"and doing an aliased self-join": newQuery
			mod: -> @join parent: "t1"
			sql: "SELECT t1.* FROM t1 INNER JOIN t1 AS parent"

		"and joining another table with a left outer join": newQuery
			mod: -> @join "t2", type: 'left outer'
			sql: "SELECT t1.* FROM t1 LEFT OUTER JOIN t2"

	"When performing a SELECT with fields": newQuery
		topic: -> select.from 't1', ['col1', 'col2']
		sql: "SELECT t1.col1, t1.col2 FROM t1"

		"and doing a GROUP BY": newQuery
			mod: -> @groupBy "col2"
			sql: "SELECT t1.col1, t1.col2 FROM t1 GROUP BY t1.col2"

		"and joining another table": newQuery
			mod: -> @join "t2"
			sql: "SELECT t1.col1, t1.col2 FROM t1 INNER JOIN t2"

			"and fields are added": newQuery
				mod: -> @fields "col1", "col5"
				sql:	"SELECT t1.col1, t1.col2, t2.col1, t2.col5 FROM t1 INNER JOIN t2"
				msg: "new fields use last table"

).export(module)
