var g = require('../../lib')
var test = require('tap').test

test("Marshalling", function (t) {
  t.plan(1)

  t.test("Unmarshal visitor", function (t) {
    t.plan(2);

    t.test('Unmarshal visitor `before`', function (t) {
      t.plan(2)
      var unmarshal = g.unmarshaller({
        before: function (data, path) {
          if (data._type === 'Relation') {
            t.ok(Array.isArray(path), 'path argument is an array')
            t.equal(data.value, 'my_table');
          }
        }
      })
      unmarshal(g.select('my_table').toJSON())
    })

    t.test('Unmarshal visitor `after`', function (t) {
      t.plan(1)
      var unmarshal = g.unmarshaller({
        after: function (object, path) {
          if (object instanceof g.nodes.Relation) {
            t.equal(object.value, 'my_table');
          }
        }
      })
      unmarshal(g.select('my_table').toJSON())
    })
  })
})
