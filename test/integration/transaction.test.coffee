#!/usr/bin/env coffee

helpers = require('../helpers')

helpers.each_engine "Transactions", (tx, t) ->
  t.plan(4)

  tx.engine.query """CREATE TABLE people (
    name varchar(255),
    location varchar(255),
    PRIMARY KEY (name)
  )""", ->

    tx.insert("people", {name: 'Stephen', location: 'Montreal'}).execute()
    tx.select('people').execute (err, res) ->
      throw err if err
      console.log('selected')
      t.ok(res && (res.length is 1), "Inserted data is visible")
      t.deepEqual(res, [{name: 'Stephen', location: 'Montreal'}])
      tx.engine.select("people").execute (err, res) ->
        throw err if err
        t.ok(!(res?.length), "Transaction is isolated")

        tx.rollback (err) ->
          throw err if err
          tx.select("people").execute (err, res) ->
            t.ok(!(res?.length), "Transaction rolled back")
