var g = require('../../lib')
require('tap').test(function (t) {
  t.deepEqual(
    g.select('t1', function () { this.where({x: {gt: 1}}) }).compile(),
    ["SELECT * FROM t1 WHERE t1.x > $1", [1]]
  )

  t.deepEqual(
    g.update('t1', function () {
      this.set({x: 12})
      this.where({x: {gt: 1}})
    }).compile(),
    ["UPDATE t1 SET x = $1 WHERE t1.x > $2", [12, 1]]
  )

  t.deepEqual(
    g.insert('t1', ['col_a', 'col_b'], function () {
      this.addRow([1, 2])
    }).compile(),
    ["INSERT INTO t1 (col_a, col_b) VALUES ($1, $2)", [1, 2]]
  )

  t.deepEqual(
    g['delete']('t1', function () { this.where({x: 1}) }).compile(),
    ["DELETE FROM t1 WHERE t1.x = $1", [1]]
  )

  t.end()
})
