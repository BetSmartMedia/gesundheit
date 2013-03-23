module.exports = (klazz) ->
  klazz::returning = (cols...) ->
    if cols.length is 1 and Array.isArray(cols[0])
      cols = cols
    @q.addReturning cols
    return @
