#!/usr/bin/env coffee

helpers = require('../helpers')

helpers.each_engine "Transactions", (db, t) ->
  t.plan(4)
  db.transaction (err, tx) ->
    throw err if err
    if db.name is 'mysql'
      tx.query "SET autocommit = 0"
      tx.query("SET storage_engine = INNODB")
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
