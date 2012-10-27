{test}  = require('tap')
g = require('../')

dbname = 'gesundheit_test'

engine_params =
  mysql: [
    "mysql://root@localhost/#{dbname}"
    {
      max: 2
      afterCreate: (conn, done) ->
        conn.query "SET autocommit = 0", (err) ->
          return done(err) if err
          conn.query "SET storage_engine = INNODB", done
    }
  ]
  postgres: [
    "postgres://postgres@localhost/#{dbname}"
    { max: 2 }
  ]

exports.each_engine = (test_name, engine_names, callback) ->
  ###
  Run ``callback(db, tap_test)`` where ``db`` is an engine pointed at an empty
  database, and ``tap_test`` is a node-tap test object
  
  :param engine_names: (Optional) list of engine names to test against.
  ###
  if not callback
    callback = engine_names
    engine_names = Object.keys(engine_params)

  i = 0
  do nextEngine = ->
    return process.nextTick(process.exit) unless engine_name = engine_names[i++]
    test "#{test_name} - #{engine_name}", (t) ->
      db = g.engine.apply(null, engine_params[engine_name])
      tx = db.begin (err, tx) ->
        throw err if err
        console.log "transaction open"
        t.listeners('end').unshift ->
          tx.rollback() if tx.state() is 'open'
        callback tx, t
      tx.log = console.error

      t.on 'end', db.close.bind(db)
      t.on 'end', nextEngine
