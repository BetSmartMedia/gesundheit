var nodes    = require('../../lib/nodes')
var dialects = require('../../lib/dialects')

var test = require('tap').test

test('Relation Node', function (t) {
  var n = nodes.toRelation('rel')
  t.equal(n.copy().value, 'rel', "copying it keeps the name")
  t.end()
})

test("Update Node", function (t) {
  var n = new nodes.Update({table: 't1'})
  t.equal(n.relation.ref(), 't1', "it has a relation with the right name")
  n = n.copy()
  t.equal(n.relation.ref(), 't1',
          "copying it keeps the original relation name")
  t.end()
})

test("Text Helper", function (t) {
  t.test("expected interface", function (t) {
    var n = nodes.text("x BETWEEN 1 AND 10")
    t.equal(n.constructor, nodes.TextNode, 'creates a TextNode')
    t.type(n.as, 'function', 'text nodes have an "as" method')
    t.type(n.eq, 'function', 'text nodes have an "eq" method') // Comparable
    t.end()
  })

  t.test("positional params", function (t) {
    var n = nodes.text("x BETWEEN $0 AND $1", [1, 10])
    var d = new dialects.base()
    t.deepEqual(d.compile(n), ["x BETWEEN $1 AND $2", [1, 10]])
    t.end()
  })

  t.test("named params", function (t) {
    var n = nodes.text("x BETWEEN $start AND $end", {end: 10, start: 5})
    var d = new dialects.base()
    t.deepEqual(d.compile(n), ["x BETWEEN $1 AND $2", [5, 10]])
    t.end()
  })

  t.test("with missing bind vals", function (t) {
    var n = nodes.text("x = $0")
    var d = new dialects.base()
    t.throws(function () { d.compile(n) },
      'exception thrown when parameters are missing')
    t.end()
  })

  t.end()
})

test('exists/notExists helpers', function (t) {
  var select = require('../../').select
  t.equal(
    select('t1')
      .where(nodes.notExists(select('t1', ['id']).where({id: 3})))
      .render(),
    "SELECT * FROM t1 WHERE NOT EXISTS " +
    "(SELECT t1.id FROM t1 WHERE t1.id = $1)",
    "Can create NOT EXISTS conditions using subqueries"
  )

  t.equal(
    select('t1')
      .where(nodes.exists(select('t1', ['id']).where({id: 3})))
      .render(),
    "SELECT * FROM t1 WHERE EXISTS (SELECT t1.id FROM t1 WHERE t1.id = $1)",
    "Can create EXISTS conditions using subqueries"
  )
  t.end()
})

test('tuple helper', function (t) {
  var subject = nodes.tuple([42, nodes.toField('bar')])


  t.equal(
    nodes.Binary,
    subject.compare('IN', [[1, 2], [3, 4]]).constructor,
    "tuples are comparable")

  t.test('constructor and rendering', function (t) {
    var dialect = new dialects.base()
    t.deepEqual(
      subject.nodes.map(function (it) { return it.constructor }),
      [nodes.Parameter, nodes.Field],
      'Calls toParams on input')
    t.deepEquals(dialect.compile(subject), ["($1, bar)", [42]], "Has params")
    t.end()
  })

  t.end()
})

