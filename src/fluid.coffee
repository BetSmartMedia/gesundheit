module.exports = (fn) ->
  ->
    fn.apply(@, arguments)
    @
