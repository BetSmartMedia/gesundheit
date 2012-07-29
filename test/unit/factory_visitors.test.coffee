assert = require('assert')
newQuery = require('./macros').newQuery
g = require '../../lib'

test = (expect, query) ->
  if typeof expect is 'string'
    assert.equal(expect, query.compile()[0])
  else
    assert.deepEqual(expect, query.compile())

test "SELECT * FROM t1 WHERE t1.x > ?",
  g.select 't1', -> @where x: gt: 1

test "UPDATE t1 SET x = ? WHERE t1.x > ?",
  g.update 't1', ->
    @set(x: 12)
    @where x: {gt: 1}

test "INSERT INTO t1 (a, b) VALUES (?, ?)",
  g.insert 't1', ['a', 'b'], -> @addRow([1, 2])

test "DELETE FROM t1 WHERE t1.x = ?",
  g.delete 't1', ->
    @where(x: 1)

console.log('ok')
