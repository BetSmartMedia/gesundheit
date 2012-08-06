{test}  = require('tap')
g = require('../')

['pg', 'mysql-compat'].forEach (mod) ->
  require(mod).defaults.idleTimeoutMillis = 2000

engine_params =
  mysql:
    user: "root"
    password: ""
    host: "127.0.0.1"
  postgres:
    user: "postgres"
    password: ""
    host: "127.0.0.1"

exports.each_engine = (test_name, engine_names, callback) ->
  ###
  Run ``callback(db, tap_test)`` where ``db`` is an engine pointed at an empty
  database, and ``tap_test`` is a node-tap test object
  
  :param engine_names: (Optional) list of engine names to test against.
  ###
  if not callback
    callback = engine_names
    engine_names = Object.keys(engine_params)

  dbname = 'gesundheit_test'
  i = 0
  do nextEngine = ->
    return process.nextTick(process.exit) unless engine_name = engine_names[i++]
    test "#{test_name} - #{engine_name}", (t) ->
      engineFactory = g.engines[engine_name]
      engine = engineFactory(engine_params[engine_name])
      engine.connect (err, conn) ->
        drop_db = if engine_name is 'mysql'
          "DROP DATABASE IF EXISTS #{dbname}"
        else
          "DROP DATABASE #{dbname}"
        conn.query drop_db, (err) ->
          console.warn(err) if err
          conn.query "CREATE DATABASE #{dbname}", (err) ->
            throw err if err
            if engine_name is 'mysql'
              conn.query("USE #{dbname}")
            engine.params.database = dbname
            callback engine, t

      t.on 'end', engine.destroy
      t.on 'end', nextEngine

