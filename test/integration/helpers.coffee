fs     = require('fs')
{test} = require('tap')
g      = require('../../')

DBNAME = 'gesundheit_test'
SQLITE3_FILE = "/tmp/#{DBNAME}"

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
    "sqlite3:///#{SQLITE3_FILE}"
    { max: 2 }
  ]

exports.eachEngine = (testName, tables, callback) ->
  ###
  Run ``callback(db, tap_test)`` where ``db`` is an engine pointed at an empty
  database, and ``tap_test`` is a node-tap test object
  
  :param engineNames: (Optional) list of engine names to test against.
  ###
  if not callback
    callback = tables
    tables = null
  engineNames = Object.keys(ENGINE_PARAMS)

  i = 0
  do nextEngine = ->
    unless engineName = engineNames.shift()
      return process.nextTick(process.exit)

    if engineName is 'sqlite3' and fs.existsSync SQLITE3_FILE
      fs.unlinkSync SQLITE3_FILE

    test "#{testName} - #{engineName}", (t) ->
      db = g.engine.apply(null, ENGINE_PARAMS[engineName])
      t.on 'end', db.close.bind(db)
      t.on 'end', nextEngine
      if tables then db.pool.acquire (err, conn) ->
        throw err if err
        createTables conn, tables, (err) ->
          throw err if err
          db.pool.release(conn)
          callback db, t
      else
        callback db, t

createTables = (conn, tables, callback) ->
  queries = for table, definition of tables
    conn.query "DROP TABLE IF EXISTS #{table}"
    columns = for col, type of definition when col isnt 'primary_key'
      "#{col} #{type}"
    if definition.primary_key
      columns.push("PRIMARY KEY (#{definition.primary_key})")
    conn.query("CREATE TABLE #{table} (#{columns.join(', ')})")

  queries.pop().once('end', callback.bind(null, null))
