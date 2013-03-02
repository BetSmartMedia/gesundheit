var update = require('../../lib').update
require('tap').test('UPDATE queries', function (t) {
  var q = update('t1').copy().set({x: 45})

  t.deepEqual(q.compile(),
    ["UPDATE t1 SET x = $1", [45]],
    "and setting a column to a value")

  t.deepEqual(q.copy().limit(10).compile(),
    ["UPDATE t1 SET x = $1 LIMIT 10", [45]],
    "and adding a limit")

  t.deepEqual(q.copy().where({x: 44}).compile(),
    ["UPDATE t1 SET x = $1 WHERE t1.x = $2", [45, 44]],
    "and adding a condition")
      
  t.deepEqual(q.copy().order({age: 'DESC'}).limit(10).compile(),
    ["UPDATE t1 SET x = $1 ORDER BY t1.age DESC LIMIT 10", [45]],
    "and adding an order")

  t.deepEqual(q.copy().where({x: null}).compile(),
    ["UPDATE t1 SET x = $1 WHERE t1.x IS NULL", [45]],
    "and adding an IS NULL condition")

  t.deepEqual(q.copy().returning('*').compile(),
    ["UPDATE t1 SET x = $1 RETURNING *", [45]],
    "and returning rows")

  t.end()
})

