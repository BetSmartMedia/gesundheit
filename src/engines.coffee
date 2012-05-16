
dialects = require('./dialects')

postgres = (dsn) ->
  ###
  Create a new Postgres engine using a DSN compatible with
  ``require('pg').connect(dsn)``. This generally has the from:

  ``<scheme>://<user>@<host>[:<port>]/<database>``

  This will ``require('pg')`` and attempt to use the 'native' interface if it's
  available, so that module must be installed for this to work.
  ###
  pg = require('pg')
  if pg.native
    pg = pg.native

  dialect = new dialects.Postgres

  engine =
    render: dialect.render.bind(dialect)
    connect: (cb) ->
      pg.connect dsn, (err, client) ->
        client.engine = engine if client
        cb err, client

    stream: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query(sql, params)
        .on('row', cb.bind(null, null))
        .on('error', cb)

    execute: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query(sql, params, cb)
    
mysql = (opts) ->
  ###
  Create a new MySQL engine using an object that is compatible with
  ``require('node-mysql').createClient(opts)``, 

  Additionally, you can specify extra options for ``generic-pool`` by
  including them as an object in ``opts.pool``. The ``create`` and
  ``destroy`` pool functions will be created for you.
  
  This will ``require('mysql')`` and ``require('generic-pool')`` so those
  modules must be installed and loadable for this function to work.
  ###
  mysql = require('mysql')
  {Pool} = require('generic-pool')
  dialect = new dialects.MySQL
  poolOpts = opts.pool or {}
  poolOpts.name or= opts.user+opts.host+opts.port+opts.database
  poolOpts.create = mysql.createClient.bind(null, opts)
  poolOpts.destroy = (client) -> client.end()
  pool = Pool poolOpts
  engine =
    render: dialect.render.bind(dialect)
    connect: pool.acquire.bind(pool)
    stream: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query(sql, params)
        .on('row', cb.bind(null, null))
        .on('end', (res) ->
          pool.release client unless client is query.client
          if res then cb null, null, res
        )
        .on('error', cb)

    execute: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query sql, params, (err, res) ->
        pool.release client unless client is query.client
        cb err, res


fakeEngine = ->
  ###
  Create a no-op engine that simply returns the compiled SQL and parameter
  array to the result callback. This will be the default until you over-ride
  with ``gesundheit.defaultEngine = myAppEngine``.
  ###
  bd = new dialects.BaseDialect
  engine =
    render: bd.render.bind(bd)
    connect: (cb) -> cb null, passthroughClient
    stream: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query sql, params, cb
    execute: withClient (client, query, cb) ->
      [sql, params] = query.compile()
      client.query sql, params, cb

  passthroughClient =
    engine: engine
    query: (sql, params, cb) ->
      if cb
        process.nextTick cb.bind(null, null, [sql, params])

  return engine

withClient = (original) ->
  ###
  Decorate a method so that it will be called with a connected client prepended
  to the argument list. The method **must** receive an object bound to an engine
  as it's first argument.
  ###
  (obj, args...) ->
    if client = obj.connection
      args = [client, obj].concat(args)
      original.apply @, args
    else
      obj.engine.connect (err, client) ->
        return cb err if err
        args = [client, obj].concat(args)
        original.apply @, args

module.exports = {mysql, postgres, fakeEngine, withClient}
