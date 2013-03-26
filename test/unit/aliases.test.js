var g = require('../../lib')
var test = require('tap').test

test("Aliases", function (t) {

  t.plan(4)

  var dialect = new g.dialects.base()

  t.test('TextNode', function (t) {
    t.plan(2)
    var it = g.text('col -> $0', ['param1']).as('my_alias')
    dialect.reset()
    t.equal(dialect.compile(it), '(col -> $1) AS my_alias')
    t.deepEqual(dialect.params, ['param1'], "has params")
  })

  t.test('Relation', function (t) {
    t.plan(1)
    var it = g.toRelation('some_table').as('my_alias')
    t.equal(dialect.compile(it), 'some_table AS my_alias')
  })

  t.test('Projection', function (t) {
    t.plan(2)
    var it = g.toProjection('some_table.some_column').as('my_alias')
    t.equal(dialect.compile(it), 'my_alias',
            'compiles just the alias name outside of a ProjectionSet')

    var cs = new g.nodes.ColumnSet([it])
    t.equal(dialect.compile(cs), 'some_table.some_column AS my_alias',
            'compiles full projection and alias inside ProjectionSet')
  })

  t.test('SqlFunction', function (t) {
    t.plan(3)
    var it = g.sqlFunction('FUNC', [1]).as('my_alias')
    t.equal(dialect.compile(it), 'my_alias',
            'compiles just the alias name outside of a ProjectionSet')

    var cs = new g.nodes.ColumnSet([it])
    dialect.reset()
    t.equal(dialect.compile(cs), 'FUNC($1) AS my_alias',
            'compiles full function and alias inside ProjectionSet')
    t.deepEqual(dialect.params, [1])
  })
})
