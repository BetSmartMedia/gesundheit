module.exports = (fn, msg) ->
  ->
    console.warn('DEPRECATED: ', msg)
    fn.apply(@, arguments)

module.exports.rename = (fn, oldName, newName) ->
  module.exports(
    fn,
    "#{oldName} has been renamed to #{newName} and will be removed in a future release.")
