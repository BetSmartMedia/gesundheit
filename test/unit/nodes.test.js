nodes = require('../../lib/nodes')

test = require('tap').test

test('Relation Node', function (t) {
  var n = nodes.toRelation('rel')
  t.equal(n.copy().value, 'rel', "copying it keeps the name")
  t.end()
})

test("Update Node", function (t) {
  var n = new nodes.Update(nodes.toRelation('t1'))
  t.ok(n instanceof nodes.FixedNamedNodeSet, "it's a FixedNamedNodeSet")
  t.equal(n.relation.ref(), 't1', "it has a relation with the right name")
  var n = n.copy()
  t.equal(n.relation.ref(), 't1', "copying it keeps the original relation name")
  t.end()
})
