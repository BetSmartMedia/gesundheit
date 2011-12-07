vows = require 'vows'
assert = require 'assert'
{
  Update,
  Relation,
  FixedNamedNodeSet,
  Binary,
  Parameter,
  When
} = require '../lib/nodes'

vows.describe('UPDATE node').addBatch(
  "Given a Relation node,":
    topic: -> new Relation 'rel'
    "copying it":
      topic: (n) -> n.copy()
      "keeps the name": (e, n) -> assert.equal n.value, 'rel'

  "Given an Update node,":
    topic: -> new Update new Relation 't1'

    "it's a FixedNamedNodeSet": (err, node) ->
      assert.instanceOf node, FixedNamedNodeSet
    "it has a relation with the right name": (err, node) ->
      assert.equal node.relation.ref(), 't1'

    "copying it":
      topic: (node) -> node.copy()
      "keeps the original relation name": (node) ->
        assert.equal node.relation.ref(), 't1'

).export(module)
