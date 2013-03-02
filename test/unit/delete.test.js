var DELETE = require('../../lib').DELETE

require('tap').test("DELETE queries", function (t) {
  var q = DELETE('t1')
  t.equal('DELETE FROM t1', q.render())
  t.equal('DELETE FROM t1 LIMIT 10', q.limit(10).render())
  t.equal("DELETE FROM t1 ORDER BY t1.age DESC LIMIT 10",
          q.order({age: 'DESC'}).render())
  t.equal('DELETE FROM t1 RETURNING *', DELETE('t1').returning('*').render())
  t.end()
})
