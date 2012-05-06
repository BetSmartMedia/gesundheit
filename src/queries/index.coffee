
uc      = (str) -> str.toUpperCase()
ucfirst = (str) -> str[0].toUpperCase() + str.substring 1
for queryType in ['select', 'update', 'insert', 'delete']
  query = require "./#{queryType}"
  for name in [queryType, uc(queryType), ucfirst(queryType)]
    exports[name] = query
