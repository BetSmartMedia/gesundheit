#!/usr/bin/env coffee

tables =
  src:  {a: 'int', b: 'int'}
  dest: {a: 'int', b: 'int'}

require('./helpers').eachEngine "Insert from select", tables, (db, t) ->
  t.plan(1)
  testData = ({a: i, b: 10 - i} for i in [1..10])
  tx = db.begin()
  t.on('end', tx.rollback.bind(tx))
  tx.insert("src", ['a', 'b']).addRows(testData...).execute()
  tx.insert("dest", ['a', 'b']).from(db.select('src')).execute()
  tx.select('dest').execute (err, res) ->
    throw err if err
    t.deepEqual res.rows, testData
