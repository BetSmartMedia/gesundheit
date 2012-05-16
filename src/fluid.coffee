module.exports = (object, names...) ->
  for name in names
    object::[name] = fluidWrapper object::[name]

fluidWrapper = (fn) ->
  ->
    fn.apply(@, arguments)
    @
