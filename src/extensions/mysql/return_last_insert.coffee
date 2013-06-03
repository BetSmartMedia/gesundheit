nodes = require '../../nodes'

module.exports = (query) ->
  exec = query.execute
  query.execute = (cb) ->
    toReturn = @q.returning.nodes.slice()
    unless toReturn.length
      return exec.call(@, cb)

    @q.returning.nodes.length = 0

    tableName = switch @q.relation.constructor
      when nodes.Relation then @q.relation.value
      when nodes.Relation.Alias then @q.relation.obj.value
      else throw new Error("@q.relation is not a Relation?")

    proxy = new EmitterProxy

    exec.call @, (err, res) =>
      if err
        if cb then cb(err) else proxy.emit('error', err)
      else
        id = res.insertId
        if toReturn.length is 1 and toReturn[0].value is 'id'
          proxy.emit 'row', {id}
          proxy.emit 'end', {rows: [{id}]}
        else
          select = @engine.select(tableName, toReturn).where({id})
          proxy.intercept ['error', 'row', 'end'], select.execute cb

    return proxy

{EventEmitter} = require 'events'

class EmitterProxy extends EventEmitter
  intercept: (events, object) ->
    self = @
    events.forEach (event) =>
      object.on event, (args...) =>
        @emit event, args...
