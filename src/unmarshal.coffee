unmarshallable = Object.create require('./nodes'), {
  InsertQuery: value: require './queries/insert'
  SelectQuery: value: require './queries/select'
  UpdateQuery: value: require './queries/update'
  DeleteQuery: value: require './queries/delete'
}

# The current (global) unmarshal callback
unmarshal = null

module.exports = (visitor, object) ->
  path = []
  recur = (object, k="") ->
    return object if typeof object != 'object'

    path.push(k)

    if Array.isArray(object)
      result = object.map(recur)
    else
      if !(type = object._type)
        result = {}
        result[k] = recur(v, k) for k, v of object
        result
      else if (ctor = unmarshallable[type])?.unmarshal?
        visitor?.before?(object, path)
        result = ctor.unmarshal(object, recur)
        visitor?.after?(result, path)
      else
        err = new Error "Cannot unmarshall #{type} @ #{path.join('/')}"
        err.path = path.slice()
        path = []
        throw err

    path.pop(k)
    result

  # A little manual currying
  if arguments.length > 1
    recur(object)
  else
    recur

module.exports.allow = unmarshallable
