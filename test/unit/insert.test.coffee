vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

{insert, select, DEFAULT} = require '../../lib'


suite = vows.describe('INSERT queries').addBatch(
	"A new INSERT without fields errors": ->
		assert.throws (-> insert 't1'), Error

	"A new INSERT":
		topic: -> insert 't1', ['a', 'b']

		"errors when adding a row of the wrong length": (q) ->
			assert.throws (-> q.addRow [1, 2, 3]), Error

		"with a single row": newQuery
			mod: -> @addRow a: 2, b: 50
			sql: "INSERT INTO t1 (a, b) VALUES (?, ?)"
			par: [2, 50]

		"with multiple rows": newQuery
			mod: -> @addRows [1,2], [3,4]
			sql: "INSERT INTO t1 (a, b) VALUES (?, ?), (?, ?)"
			par: [1,2,3,4]

		"extracts the correct fields from an object": newQuery
			mod: -> @addRow a: 1, c: 3, d: 99
			sql: "INSERT INTO t1 (a, b) VALUES (?, DEFAULT)"
			par: [1]
			
		"from a SELECT query": newQuery
			mod: -> @from select('t2', ['x', 'y']).where(x: {gt: 50})
			sql: "INSERT INTO t1 (a, b) SELECT t2.x, t2.y FROM t2 WHERE t2.x > ?"
			par: [50]
).export(module)
