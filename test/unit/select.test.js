var g = require('../../lib')
var select = g.select
var sqlFunction = g.sqlFunction
var LEFT_OUTER = g.LEFT_OUTER

var test = require('tap').test

test("SELECT queries", function (t) {
  t.equal(select('t1').render(), "SELECT * FROM t1", "simplest possible query")

  t.equal(select('case', ['when']).render(),
    'SELECT "case"."when" FROM "case"',
    "Quoting identifiers")

  t.test("ORDER BY clauses", function (t) {
    var q = select('t1')
    t.equal(q.copy().order({quantity: 'ASC'}).render(),
      "SELECT * FROM t1 ORDER BY t1.quantity ASC",
      "object ORDER BY")

    t.equal(q.copy().order('quantity').render(),
      "SELECT * FROM t1 ORDER BY t1.quantity",
      "string ORDER BY")

    t.equal(q.copy().order('quantity descending').render(),
      "SELECT * FROM t1 ORDER BY t1.quantity DESC",
      "string ORDER BY with a direction")

    t.throws(function () { q.order({x: "LEFTWISE"}) },
      "invalid ORDER BY direction throws an error")

    t.end()
  })

  t.test("WHERE clauses", function (t) {
    var q = select('t1')
    t.deepEqual(q.copy().where({x: 2}).compile(),
      ["SELECT * FROM t1 WHERE t1.x = $1", [ 2 ]],
      "and a where clause is added")

    t.deepEqual(q.copy().where({x: {lt: 10}}).compile(),
      ["SELECT * FROM t1 WHERE t1.x < $1", [ 10 ]],
      "and a 'lt' where clause is added")

    t.deepEqual(q.copy().or({x: {lt: 10}, y: 10}).compile(),
      ["SELECT * FROM t1 WHERE (t1.x < $1 OR t1.y = $2)", [10, 10]],
      "and an 'OR' where clause is added")

    t.deepEqual(q.copy().where({x: {"in": [1, 2, 3]}}).compile(),
      ["SELECT * FROM t1 WHERE t1.x IN ($1, $2, $3)", [1, 2, 3]],
      "and an 'IN' where clause is added")

    t.deepEqual(q.copy().where({x: {"notIn": [1, 2, 3]} }).compile(),
      ["SELECT * FROM t1 WHERE t1.x NOT IN ($1, $2, $3)", [1, 2, 3]],
      "and an 'NOT IN' where clause is added")

    t.end()
  })

  t.test("basic JOIN", function (t) {
    var q = select('t1').join("t2")
    t.equal(q.render(),
      "SELECT * FROM t1 INNER JOIN t2",
      "default join")

    t.throws(function () { q.join("t1") }, "self-joins require alias")

    t.throws(function () { q.table("blah") },
      "switching to an unjoined table throws an Error")

    t.equal(q.copy().fields("b").render(),
      "SELECT t2.b FROM t1 INNER JOIN t2",
      "fields are added to the second table")

    t.equal(q.copy().fields("b").fields().render(),
      "SELECT * FROM t1 INNER JOIN t2",
      "clearing fields")

    t.equal(q.copy().focus("t1").fields("x", "y").render(),
      "SELECT t1.x, t1.y FROM t1 INNER JOIN t2",
      "fields can be added on the first table")

    t.end()
  })

  t.test("more advanced joins", function (t) {
    t.equal(
      select('t1').visit(function () {
        this.join("t2", {on: {x: this.c('t1', 'y')}})
      }).render(),
      "SELECT * FROM t1 INNER JOIN t2 ON (t2.x = t1.y)",
      "join using a clause")

    t.equals(
      select('t1').visit(function () {
        this.join("t2", {
          on: {x: this.c('t1.x'), y: this.c('t1.y')}
        })
      }).render(),
      "SELECT * FROM t1 INNER JOIN t2 ON (t2.x = t1.x AND t2.y = t1.y)",
      "joining using a clause with multiple predicates")


    t.equal(
      select('t1').join({parent: "t1"}).render(),
      "SELECT * FROM t1 INNER JOIN t1 AS parent",
      "aliased self-join")

    t.throws(
      function () { select('t1').join("t2", {type: "DOVETAIL"}) },
      "joining with an invalid join type fails")

    t.equal(
      select('t1').join("t2", {type: LEFT_OUTER}).render(),
      "SELECT * FROM t1 LEFT OUTER JOIN t2",
      "a different join type")

    t.equal(
        select('t1').join('t2', {fields: ['col1', 'col2']}).render(),
        "SELECT t2.col1, t2.col2 FROM t1 INNER JOIN t2",
        "joins with fields override star projection")
    t.end()
  })

  t.test("join with prefixFields option", function (t) {
    t.equal(
      select('t1').join('t2', {
        fields: ['col1', 'col2'],
        prefixFields: 'p_'
      }).render(),
      "SELECT t2.col1 AS p_col1, t2.col2 AS p_col2 FROM t1 INNER JOIN t2",
      "explicit prefix for joined fields")

    t.equal(
      select('t1').join('t2', {
        fields: ['col1', 'col2'],
        prefixFields: true
      }).render(),
      "SELECT t2.col1 AS t2_col1, t2.col2 AS t2_col2 FROM t1 INNER JOIN t2",
      "implicit prefix for joined fields")

    t.equal(
      select('t1').join({al: 't2'}, {
        fields: ['col1', 'col2'],
        prefixFields: true
      }).render(),
      "SELECT al.col1 AS al_col1, al.col2 AS al_col2 FROM t1 INNER JOIN t2 AS al",
      "implicit prefix for joined fields uses table alias")
    t.end()
  })

  t.test("ensureJoin", function (t) {
    var q = select('t1', ['*'])
    t.plan(2)
    q.ensureJoin('t2', {on: {id: q.c('t1', 't2_id')}, fields: ['*']})
    t.equal(q.render(),
      "SELECT t1.*, t2.* FROM t1 INNER JOIN t2 ON (t2.id = t1.t2_id)",
      "... first join")
    q.ensureJoin('t2', {on: {id: q.c('t1', 't2_id')}, fields: ['*']})
    t.equal(q.render(),
      "SELECT t1.*, t2.* FROM t1 INNER JOIN t2 ON (t2.id = t1.t2_id)",
      "... same join")

  })

  t.test("GROUP BY and HAVING", function (t) {
    var count = null
    var q = select('t1', ['col2'], function () {
      count = sqlFunction('COUNT', [this.c('col1')]).as('total')
      this.fields(count)
      this.groupBy("col2")
    })

    t.equal(q.render(),
      "SELECT t1.col2, COUNT(t1.col1) AS total FROM t1 GROUP BY t1.col2",
      "basic groupBy")

    t.equal(q.copy().having(count.gt(12)).render(),
      "SELECT t1.col2, COUNT(t1.col1) AS total " +
      "FROM t1 GROUP BY t1.col2 HAVING total > $1",
      "groupBy with HAVING")

    t.end()
  })

  t.test('Selecting from function calls', function (t) {
    t.equals(
      select(sqlFunction('myfunc', [1, 2])).render(),
      "SELECT * FROM myfunc($1, $2)",
      "Can select from a SQL function call")

    t.deepEquals(
      select(sqlFunction('myfunc', [1, 2]).as('foo')).compile(),
      ["SELECT * FROM myfunc($1, $2) AS foo", [1, 2]],
      "Can select from an aliased SQL function call")

    t.deepEquals(
      select(sqlFunction('exx', [1]).as('exx'), ['lc']).compile(),
      ['SELECT exx.lc FROM exx($1) AS exx', [1]],
      "Can select subset of columns from SQL function call")

    t.end()
  })

  t.test("misc. SELECT tricks", function (t) {
    var q = select('t1', ['col1', 'col2'])
    t.equal(q.render(),
      "SELECT t1.col1, t1.col2 FROM t1",
      "can pass fields to constructor a SELECT with fields")

    t.equal(q.copy().distinct(true).render(),
      "SELECT DISTINCT t1.col1, t1.col2 FROM t1",
      "and DISTINCT is enabled")

    t.equal(q.copy().join("t2").fields("col1", "col5").render(),
      "SELECT t1.col1, t1.col2, t2.col1, t2.col5 FROM t1 INNER JOIN t2",
      "new fields use last table")

    t.equal(select('t1').limit(100).render(),
      "SELECT * FROM t1 LIMIT 100",
      "setting a limit")

    t.equals(
      select({t1: 'LongTableName'}, [{short: 'long_field_name'}]).render(),
      "SELECT t1.long_field_name AS short FROM LongTableName AS t1",
      "Object aliases in constructor work")

    t.end()
  })

  t.end()
})
