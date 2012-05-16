# Gesundheit - Concise SQL generation in CoffeeScript

Gesundheit generates SQL, it does this using a sugary API for managing the
abstract syntax tree of a SQL statement, then compiling that AST to a
string and array of bound parameters at query execution time. For example:

    gesundheit = require('./lib')
    assert = require('assert')
    query = gesundheit.select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

    assert.deepEqual(query.compile(), [
      'SELECT chairs.chair_type, chairs.size FROM chairs WHERE chairs.chair_type = ? AND chairs.weight < ?',
      ['recliner', 25]
    ])

See [the documentation](http://betsmartmedia.github.com/gesundheit/) for more
thorough examples showing different query types, joins, query execution and more.


## Install

    npm install gesundheit

## License

MIT

## Author

Stephen Sugden <stephen@betsmartmedia.com>
