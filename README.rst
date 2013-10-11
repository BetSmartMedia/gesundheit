Gesundheit - Concise SQL generation for node.js
===============================================

.. image:: https://secure.travis-ci.org/BetSmartMedia/gesundheit.png?branch=master
  :target: http://travis-ci.org/BetSmartMedia/gesundheit

Gesundheit generates SQL using a sugary API for managing the abstract syntax
tree of a statement. After building your statement programmatically, gesundheit
can compile it to a string or execute it against your database for you, using
proper bound parameters and allowing for streaming of results.

Here's a quick example to illustrate::

    select = require('./lib').select
    assert = require('assert')
    query = select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

    assert.deepEqual(query.compile(), [
      'SELECT chairs.chair_type, chairs.size FROM chairs WHERE chairs.chair_type = ? AND chairs.weight < ?',
      ['recliner', 25]
    ])

    query.execute(console.log)

See `the documentation <http://betsmartmedia.github.com/gesundheit/>`_ for full
API documentation and more examples showing different query types, joins, query
execution and more.


Install
-------

In addition to the usual ``npm install gesundheit``, you will need to install
the driver for your database. Driver support is provided by `Any-DB
<https://github.com/grncdr/node-any-db>`_, which currently supports MySQL, Postgres
and SQLite3. So for example, if you use PostgreSQL as your database backend you
would do ``npm install --save any-db-postgres``.

License
-------

MIT

Author
-------

Stephen Sugden <glurgle@gmail.com>
