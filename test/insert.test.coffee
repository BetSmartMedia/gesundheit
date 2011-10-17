vows = require 'vows'
assert = require 'assert'
newQuery = require('./macros').newQuery

g = require '../lib'
DEFAULT = g.DEFAULT
insert  = g.Insert
select  = g.Select

suite = vows.describe('INSERT queries').addBatch(
	"A new INSERT":
		topic: -> insert.into 't1'

		"errors when adding rows without any fields": (q) ->
			assert.throws (-> q.addRow [1, 2, 3]), Error
			
		"with a single row": newQuery
			mod: -> @addRow blah: 2, nah: 50
			sql: "INSERT INTO t1 (blah, nah) VALUES (?, ?)"
			par: [2, 50]

		"with multiple rows": newQuery
			mod: -> @fields("a","b").addRows [1,2], [3,4]
			sql: "INSERT INTO t1 (a, b) VALUES (?, ?), (?, ?)"
			par: [1,2,3,4]

		"with set fields": newQuery
			mod: -> @fields("a","b","c")
			
			"errors when adding a row of the wrong length": (q) ->
				fail = -> q.addRow [1, 2]
				assert.throws(fail, Error)

			"extracts the correct fields from an object": newQuery
				mod: -> @addRow a: 1, c: 3, d: 99
				sql: "INSERT INTO t1 (a, b, c) VALUES (?, DEFAULT, ?)"
				par: [1, DEFAULT, 3]
				
		"from a SELECT query": newQuery
			mod: -> @fromQuery select.from('t2', ['x', 'y']).where(x: {gt: 50})
			sql: "INSERT INTO t1 SELECT t2.x, t2.y FROM t2 WHERE t2.x > ?"
			par: [50]
).export(module)
