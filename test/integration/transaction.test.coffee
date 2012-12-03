#!/usr/bin/env coffee

helpers = require('../helpers')

helpers.eachEngine "Transactions", (tx, t) ->
  t.plan(3)

  tx.engine.query """CREATE TABLE people (
    name varchar(255),
    location varchar(255),
    PRIMARY KEY (name)
  )""", ->

    tx.insert("people", {name: 'Stephen', location: 'Montreal'}).execute()
    tx.select('people').execute (err, res) ->
      throw err if err
      console.log('selected')
      t.equal(res?.rows.length, 1, "Inserted data is visible")
      t.deepEqual(res.rows[0], {name: 'Stephen', location: 'Montreal'})
      # Select from people on a differenct connection
      tx.engine.select("people").execute (err, res) ->
        throw err if err
        t.ok(!(res?.rows.length), "Transaction is isolated")
