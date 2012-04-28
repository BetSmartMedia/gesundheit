###
Factory functions to create engines for various databases.

This module attempts to require the ``'pg'`` and ``'mysql'`` modules and
fails silently if they are not found.
###

dialects = require('./dialects')

withClient = (original) ->
  ###
  Decorate a method so that it will be called with a connected client prepended
  to the argument list. The method **must** receive a bound query as it's first
  argument.
  ###
  (query, args...) ->
    if client = query.connection
      args = [client, query].concat(args)
      original.apply @, args
    else
      query.engine.connect (err, client) ->
        return cb err if err
        args = [client, query].concat(args)
        original.apply @, args

try
  pg = require('pg').native
catch e then try
  pg = require('pg')


# Postgres
if pg
  exports.postgres = (dsn) ->
    dialect = new dialects.PostgresDialect

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
    
# MySQL
try
  mysql = require('mysql')
  {Pool} = require('generic-pool')

if mysql and Pool
  exports.mysql = (opts) ->
    # Default no-pooling case, connect for every query (slow!)
    dialect = new dialects.MySQLDialect
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
            engine.release()
            if res then cb null, null, res
          )
          .on('error', cb)

      execute: withClient (client, query, cb) ->
        [sql, params] = query.compile()
        client.query sql, params, (err, res) ->
          pool.release client unless client is query.client
          cb err, res

# Default pass-through engine

bd = new dialects.BaseDialect
exports.fakeEngine =
  render: bd.render.bind(bd)
  connect: (cb) -> cb null, passthroughClient
  release: ->
  stream: withClient (client, query, cb) ->
    [sql, params] = query.compile()
    client.query sql, params, cb
  execute: withClient (client, query, cb) ->
    [sql, params] = query.compile()
    client.query sql, params, cb

passthroughClient =
  engine: exports.fakeEngine
  query: (sql, params, cb) ->
    if cb
      process.nextTick cb.bind(null, null, [sql, params])

