var g = require('../../lib')
require('tap').test('INSERT queries', function (t) {
  /*jshint maxlen:120*/

  t.throws(function () { g.insert('t1') }, "constructor throws if no fields given")

  var q = g.insert('t1', ['col_a', 'col_b'])

  t.throws(function () { q.addRow([1, 2, 3]) },
           "errors when adding a row of the wrong length")

  t.deepEqual(
    q.copy().addRow({col_a: 2, col_b: 50}).compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, $2)", [2, 50]],
    "can add col_a single row")

  t.deepEqual(
    q.copy().addRows([[1, 2], [3, 4]]).compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, $2), ($3, $4)", [1, 2, 3, 4]],
    "can add multiple rows")

  t.deepEqual(
    q.copy().addRow({col_a: 1, c: 3, d: 99}).compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, DEFAULT)", [1]],
    "extracts the correct fields from an object")

  t.deepEqual(
    q.copy().from(g.select('t2', ['x', 'y']).where({x: {gt: 50}})).compile(),
    ["INSERT INTO t1 (col_a, col_b) SELECT t2.x, t2.y FROM t2 WHERE t2.x > $1", [50]],
    "can source from a SELECT query"
  )

  t.deepEqual(
    q.copy()
			.addRow({col_a: 1, col_b: 2}).returning('col_a', 'col_b').compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, $2) RETURNING col_a, col_b", [1, 2]],
    "can set RETURNING columns"
  )

  t.deepEqual(
    q.copy().addRow({col_a: 1, col_b: 2}).returning('*').compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, $2) RETURNING *", [1, 2]],
    "can use star for RETURNING"
  )
  t.end()
})
