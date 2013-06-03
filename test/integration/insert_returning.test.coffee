tables =
  mytable:
    id: 'INT NOT NULL AUTO_INCREMENT'
    mycol: 'INT'
    primary_key: 'id'

require('./helpers').eachEngine "Insert returning id", tables, (db, t) ->
  t.plan(2)

  q = db.insert("mytable", ['mycol'])
  q.addRows([{mycol: 10}])
  q.returning('id')
  q.execute (err, res) ->
    if err then throw err
    t.equal(1, res.rows?.length, "One row returned")
    t.equal(1, res.rows[0].id, "Row has inserted value")
