#!/usr/bin/env coffee

helpers = require('./helpers')

tables = multi_insert: {first: 'int', second: 'int'}

helpers.eachEngine "Multi-row insert", tables, (db, t) ->
  t.plan(1)

  rows = [
    {first: 1, second: 2}
    {first: 3, second: 4}
    {first: 5, second: 6}
  ]

  db.insert('multi_insert', ['first', 'second']).addRows(rows).execute (err) ->
    throw err if err
    db.select('multi_insert', ['*']).execute (err, res) ->
      throw err if err
      t.deepEqual(res.rows, rows)
