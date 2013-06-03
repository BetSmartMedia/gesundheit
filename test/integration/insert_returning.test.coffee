tables =
  mytable:
    mycol: 'INT'
    auto_key: 'id'

require('./helpers').eachEngine "Insert returning id", tables, (db, t) ->
  t.plan(2)

  db.insert("mytable", ['mycol'], ->
    @addRow(mycol: 10)
    @returning('id')
  ).execute (err, res) ->
    if err then throw err
    console.log(res)
    t.equal(1, res.rows?.length, "One row returned")
    t.equal(1, res.rows[0].id, "Row has inserted value")
