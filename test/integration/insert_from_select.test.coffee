#!/usr/bin/env coffee

helpers = require('../helpers')

helpers.eachEngine "INSERT FROM", (db, t) ->
  t.plan(1)
  db.query """CREATE TABLE src (a int, b int)""", (err) ->
    throw err if err
    db.query """CREATE TABLE dest (a int, b int)""", (err) ->
      throw err if err

      testData = ({a: i, b: 10 - i} for i in [1..10])
      db.insert("src", ['a', 'b']).addRows(testData...).execute (err) ->
        throw err if err
        db.insert("dest", ['a', 'b']).from(db.select('src')).execute (err) ->
          throw err if err
          db.select('dest').execute (err, res) ->
            t.deepEqual res.rows, testData
