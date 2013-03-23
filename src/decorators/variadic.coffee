module.exports = (method) ->
  (first) ->
    if Array.isArray(first)
      method.call(@, first)
    else
      method.call(@, Array::slice.call(arguments))
