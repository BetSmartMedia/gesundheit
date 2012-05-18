Gesundheit - Concise SQL generation in CoffeeScript
===================================================

.. image:: https://secure.travis-ci.org/BetSmartMedia/gesundheit.png?branch=master
  :target: http://travis-ci.org/BetSmartMedia/gesundheit

Gesundheit generates SQL using a sugary API for managing the abstract syntax
tree of a statement. After building your statement programmatically, gesundheit
can compile it to a string or execute it against your database for you, using
proper bound parameters and allowing for streaming of results.

A quick example::

    gesundheit = require('./lib')
    assert = require('assert')
    query = gesundheit.select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

    assert.deepEqual(query.compile(), [
      'SELECT chairs.chair_type, chairs.size FROM chairs WHERE chairs.chair_type = ? AND chairs.weight < ?',
      ['recliner', 25]
    ])

    query.execute(console.log)

See `the documentation <http://betsmartmedia.github.com/gesundheit/>`_ for more
thorough examples showing different query types, joins, query execution and more.


Install
-------

    npm install gesundheit

License
-------

MIT

Author
-------

Stephen Sugden <stephen@betsmartmedia.com>
