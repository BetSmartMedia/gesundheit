#!/usr/bin/env coffee

helpers = require('../helpers')

helpers.each_engine "Transactions", (db, t, d) ->
  db.transaction (err, tx) ->
    throw err if err
    if db.name is 'mysql' then tx.query "SET AUTOCOMMIT = 0"
    console.error db.name
    tx.query """CREATE TABLE people (
      name varchar(255),
      location varchar(255),
      PRIMARY KEY (name)
    )"""
    tx.insert("people", {name: 'Stephen', location: 'Montreal'})
      .execute()
    tx.select('people').execute (err, res) ->
      throw err if err
      t.ok(res.rows && (res.rows.length is 1), "Inserted data is visible")
      t.deepEqual(res.rows, [{name: 'Stephen', location: 'Montreal'}])
      db.select("people").execute (err, res) ->
        t.ok(!(res && res.rows.length), "Transaction is isolated")

    tx.rollback (err) ->
      throw err if err
      tx.select("people").execute (err, res) ->
        t.ok(!(res && res.rows.length), "Transaction rolled back")
        t.end()
