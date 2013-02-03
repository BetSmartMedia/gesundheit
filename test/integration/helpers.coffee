fs     = require('fs')
{test} = require('tap')
g      = require('../../')

DBNAME = 'gesundheit_test'

ENGINE_PARAMS =
  mysql: [
    "mysql://root@localhost/#{DBNAME}"
    {
      max: 2
      onConnect: (conn, done) ->
        conn.query "SET autocommit = 0", (err) ->
          return done(err) if err
          conn.query "SET storage_engine = INNODB", (err) ->
            if err then done(err) else done(null, conn)
    }
  ]
  postgres: [
    "postgres://postgres@localhost/#{DBNAME}"
    { max: 2 }
  ]
  sqlite3: [
    "sqlite3:///tmp/#{DBNAME}"
    { max: 2 }
  ]

exports.eachEngine = (testName, engineNames, callback) ->
  ###
  Run ``callback(db, tap_test)`` where ``db`` is an engine pointed at an empty
  database, and ``tap_test`` is a node-tap test object
  
  :param engineNames: (Optional) list of engine names to test against.
  ###
  if not callback
    callback = engineNames
    engineNames = Object.keys(ENGINE_PARAMS)

  i = 0
  do nextEngine = ->
    return process.nextTick(process.exit) unless engineName = engineNames[i++]

    if engineName is 'sqlite3' and fs.existsSync SQLITE3_FILE
      fs.unlinkSync SQLITE3_FILE

    test "#{testName} - #{engineName}", (t) ->
      db = g.engine.apply(null, ENGINE_PARAMS[engineName])
      t.on 'end', db.close.bind(db)
      t.on 'end', nextEngine
      callback db, t
