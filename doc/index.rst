.. gesundheit documentation master file, created by
   sphinx-quickstart on Sun Apr 29 20:07:51 2012.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Gesundheit!
===========

.. include:: ../README.markdown
  :start-after: ===================================================
  :end-before: A quick example

Contents:

.. toctree::
   :maxdepth: 2

   index

* :ref:`genindex`

API summary
=============

.. automodule:: index

Introduction - Making queries
=============================

The main interface for building queries with gesundheit are the query manager
classes. They provide an API designed to make most query building operations
concise and fluent, while under the hood they manage an abstract syntax tree
for the query.

Creating a query manager
------------------------

All of the query managers are created with functions named after the query type
that take a table (or :ref:`alias <using-aliases>`) as their first
parameter. To demonstrate we will create a simple select query::

  select = require('gesundheit').select
  departments = select('departments')

This creates a new :class:`queries/select::SelectQuery` query instance that
generates the SQL string ``SELECT * FROM departments``. To refine the field
list we call :meth:`queries/select::SelectQuery.fields`::

  departments.fields('name', 'manager_id')

It's important to note that all of the query manager methods modify the query
**in-place** [#]_ so ``departments`` will now render to ``SELECT name,
manager_id FROM departments``.

Compiling
---------

To turn the query object into a SQL string and array of bind parameters, we
``.compile`` the query::

  assert.deepEqual(
    departments.compile(),
    [ 'SELECT name, manager_id FROM departments', [] ]
  )

`(there are no bind parameters in our query yet)`

Most often you don't really care about the SQL string and params themselves, but
want result of performing the query on an actual database. In that case you
simply use the ``.execute`` method::

  query.execute (err, res) -> console.log {err, res}

... but gesundheit can't know about how to find and connect to your database
all on it's own! To execute with a real connection you will need to `bind` the
query object to an :mod:`engine <Engines>` or `client <Clients>`_. You can bind a
query by passing an engine/client as the first parameter to those methods that
require a binding, or assigning a new ``defaultEngine`` for implicit binding.

.. _engine-usage-example:

The first step in either case is to create an engine::

  gesundheit = require('gesundheit')

  # The parameter to mysql() is the same as for mysql.createClient()
  engine = gesundheit.engines.mysql({database: 'test'})

Then we can pass it, or a client we returned by it's ``.connect`` method,
to ``query.execute``::

  query.execute engine, (err, res) -> console.log {err, res}

  engine.connect (err, client) ->
    throw err if err
    query.execute client, (err, res) -> console.log {err, res}

Finally, you can also set a new defaultEngine for implicit binding::

  gesundheit.defaultEngine = engine
  query.execute (err, res) -> console.log {err, res}

Now :meth:`queries/base::BaseQuery.execute` and other methods that need a database
client will get one from the engine automatically.

.. _using-aliases:

Aliasing tables and fields
--------------------------

Any function that accepts a ``table`` or ``field`` parameter will accept a
string, an instance of the appropriate AST node type, or an `alias object`.
Alias objects are objects with a single key-value pair where the key is an
alias name and the value is the object to be aliased. So the alias object
``{p: 'people'}`` will generate the SQL string ``people AS p``. Here is an
example of aliasing table and field names::

  # SELECT manager_id AS m_id FROM departments AS d;
  select({d: 'departments'}, [{m_id: 'manager_id'}])

(This example also shows passing a list of fields to select as the second
parameter).

.. rubric:: Footnotes

.. [#] Use :meth:`queries/base::BaseQuery.copy` if you want to generate
  multiple independent refinements from a single query instance.


Query Building API reference
============================

.. automodule:: queries/index

BaseQuery
---------

.. automodule:: queries/base

Insert
------

.. automodule:: queries/insert

SUDQuery
--------

.. automodule:: queries/sud


Select
------

Examples
^^^^^^^^

Start a select query with :func:`queries/index::exports.select`::

    light_recliners = select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

Join another table with :meth:`queries/select::SelectQuery.join`::

    men_with_light_recliners = light_recliners.copy()
      .join("people", {
        on: {chair_id: query.project('chairs', 'id')},
        fields: ['name']
      })
      .where({gender: 'M'})

Note that joining a table "focuses" it, so "gender" in ``.where({gender: 'M'})``
refers to the ``people.gender`` column. To add more conditions on an earlier
table refocus it with :meth:`queries/select::SelectQuery.focus`::

  men_with_light_recliners.focus('chairs')

Ordering and limits are added with methods of the same name::

  men_with_light_recliners
    .order(weight: 'ASC)
    .limit(5)

The entire query can also be written using :meth:`queries/base::BaseQuery.visit`
(and less punctuation) like so::

  men_with_light_recliners = select('chairs', ['chair_type', 'size']).visit ->
    @where chair_type: 'recliner', weight: {lt: 25}
    @join "people",
      on: {chair_id: @project('chairs', 'id')},
      fields: ['name']
    @where gender: 'M'
    @focus 'chairs'
    @order weight: 'ASC
    @limit 5

API
^^^

.. automodule:: queries/select

Update
------

Examples
^^^^^^^^

Updating rows that match a condition::

  update('tweeters')            # UPDATE tweeters
    .set(influential: true)     # SET tweeters.influential = true
    .where(followers: gt: 1000) # WHERE tweeters.followers > 1000;
    .execute (err, res) ->
      throw err if err
      # Woohoo

API
^^^

.. automodule:: queries/update

Delete
------

Examples
^^^^^^^^

Delete all rows that match a condition::

  # DELETE FROM tweeters WHERE tweeters.followers < 10
  delete('tweeters').where(followers: lt: 10)

API
^^^

.. automodule:: queries/delete

Engines and Binding
====================

A gesundheit query must be "bound" to an "engine" to render and/or execute. For
apps that deal with a single database, you can simply create an engine instance
during application startup, assign it to ``gesundheit.defaultEngine`` and not
have to think about binding after that.

For more complicated scenarios where you need control over the exact connections
used (e.g. transactions) you will need to understand the engine/binding system.

Engines
-------

An engine is any object that implements the following API:

  **render(query)**
    Render the given query instance to a SQL string. This method **must** be
    synchronous, and will usually just delegate to a subclass of
    :class:`dialects::BaseDialect`.

  **connect(callback)**
    Call ``callback(err, client)`` where `client` is an object with a ``query``
    method that works the same as those of the pg and mysql driver clients. The
    client must also have an ``.engine`` property that points back to the engine
    instance that created it.

  **stream([client,] query, cb)**
    If client is not given, get one by calling connect. Then execute the query,
    calling ``cb(err, row)`` for each row in the result.

  **execute([client,] query, cb)**
    If client is not given, get one by calling connect. Then execute the query,
    calling ``cb(err, result)`` with the full query results.

Gesundheit exports factory functions for creating :func:`engines::postgres` and
:func:`engines::mysql` engines:

.. automodule:: engines

Bindings
--------

The render, compile, stream, and execute methods of
:class:`queries/base::BaseQuery` all require an engine to do their work. Rather
than requiring the engine to be passed to each of these methods, the query can
be "bound" to an engine or client object.

Queries are bound to such "bindable" objects in one of 3 ways:

  1. Using :meth:`queries/base::BaseQuery.bind`.

  2. A bindable object can be given as the first parameter to methods that require
     the query to be bound (e.g.  :meth:`queries/base::BaseQuery.execute`).

  3. If a method that requires a binding is called on an unbound query (and no
     bindable is given) the value of ``gesundheit.defaultEngine`` will be used.

Dialects
========

.. automodule:: dialects

Nodes
=============

.. automodule:: nodes
