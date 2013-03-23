variadic = require '../decorators/variadic'
fluid    = require '../decorators/fluid'

module.exports = (klazz) ->
  klazz::returning = fluid variadic (cols) ->
    @q.addReturning cols
    return @
