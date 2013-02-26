/**
 * This file contains tests for query examples brought up in GH issues.
 * If you come up with a particularly devious query, please add it here and
 * send a pull request. :)
 */

var g = require('../../lib')

var test = require('tap').test

test("https://github.com/BetSmartMedia/gesundheit/issues/21", function (t) {
  var subselect = g.select('t1', [g.text('1')]).where({id: 3})
  var source = g.select('t1', [g.text("$0, $1, $2", [3, 'C', 'Z'])])
    .where(g.notExists(subselect))

  var insert = g.insert('t1', ['id', 'f1', 'f2']).from(source)

  t.deepEqual(insert.compile(), [
    'INSERT INTO t1 (id, f1, f2) ' +
    'SELECT $1, $2, $3 FROM t1 WHERE NOT EXISTS ' +
    '(SELECT 1 FROM t1 WHERE t1.id = $4)',
    [3, 'C', 'Z', 3]
  ])
  t.end()
})

