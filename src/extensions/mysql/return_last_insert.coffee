nodes = require '../../nodes'

module.exports = (query) ->
  exec = query.execute
  query.execute = (callback) ->
    toReturn = @q.returning.nodes.slice()

    unless toReturn.length
      return exec.call(@, callback)

    @q.returning.nodes.length = 0

    tableName = @q.relation.value

    proxy = new EmitterProxy

    exec.call @, (err, res) =>
      if err
        if cb then cb(err) else proxy.emit('error', err)
      else
        console.log(res)
        id = res.rows.insertId
        if toReturn.length is 1 and toReturn[0].value is 'id'
          row = {id}
          result = rows: [row]
          proxy.emit 'row', row
          proxy.emit 'end', result
          callback(null, result) if callback
        else
          select = @engine.select(tableName, toReturn).where({id})
          proxy.intercept ['error', 'row', 'end'], select.execute(callback)

    return proxy

{EventEmitter} = require 'events'

class EmitterProxy extends EventEmitter
  intercept: (events, object) ->
    self = @
    events.forEach (event) =>
      object.on event, (args...) =>
        @emit event, args...
