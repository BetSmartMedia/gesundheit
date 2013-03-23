var g = require('../../lib')
var test = require('tap').test

test("Aliases", function (t) {

  t.plan(4)

  var dialect = new g.dialects.base()

  t.test('TextNode', function (t) {
    t.plan(2)
    var it = g.text('Arbitrary SQL text', ['param1']).as('my_alias')
    t.deepEqual(it.params(), ['param1'], "has params")
    t.equal(dialect.render(it), '(Arbitrary SQL text) AS my_alias')
  })

  t.test('Relation', function (t) {
    t.plan(1)
    var it = g.toRelation('some_table').as('my_alias')
    t.equal(dialect.render(it), 'some_table AS my_alias')
  })

  t.test('Projection', function (t) {
    t.plan(2)
    var it = g.toProjection('some_table.some_column').as('my_alias')
    t.equal(dialect.render(it), 'my_alias',
            'renders just the alias name outside of a ProjectionSet')

    var ps = new g.nodes.ColumnSet([it])
    t.equal(dialect.render(ps), 'some_table.some_column AS my_alias',
            'renders full projection and alias inside ProjectionSet')
  })

  t.test('SqlFunction', function (t) {
    t.plan(3)
    var it = g.sqlFunction('MY_FUNC', [1]).as('my_alias')
    t.equal(dialect.render(it), 'my_alias',
            'renders just the alias name outside of a ProjectionSet')

    var ps = new g.nodes.ColumnSet([it])
    t.equal(dialect.render(ps), 'MY_FUNC($1) AS my_alias',
            'renders full function and alias inside ProjectionSet')
    t.deepEqual(it.params(), [1])
  })
})
