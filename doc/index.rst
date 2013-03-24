.. gesundheit documentation master file, created by
   sphinx-quickstart on Sun Apr 29 20:07:51 2012.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Gesundheit!
===========

.. include:: ../README.rst
  :start-after: ===============================================
  :end-before: Here's a quick example

Contents
--------

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
**in-place** [#]_ so ``departments`` will now render to ``SELECT
departments.name, departments.manager_id FROM departments``.

Compiling & Executing
---------------------

To turn the query object into a SQL string and array of bound parameters, we
``.compile`` the query::

  assert.deepEqual(
    departments.compile(),
    [ 'SELECT name, manager_id FROM departments', [] ]
  )

`(there are no parameters to our query yet)`

Most often you don't really care about the SQL string and params themselves, but
want result of performing the query on an actual database. In that case you
simply use the ``.execute`` method::

  query.execute(function (err, res) { console.log(err, res) })

"but..." you might be saying, "gesundheit can't know how connect to my database
all on it's own!" and you are 100% correct. In order to execute against a real
database the query must be `bound` to an :class:`engine::Engine`. Queries are
bound to an engine when they are created [#]_ and use that engine for rendering
and executing themselves.

.. _engine-usage-example:

Using a real database
---------------------

So far, we have been using gesundheits built-in mock engine, which does nothing
but render SQL strings. In order to use a real database, we need to create our
own engine object to use::

  gesundheit = require('gesundheit')

  db = gesundheit.engine('mysql://localhost/test')

The database URL above can point to any database supported by Any-DB_, which
includes MySQL, Postgres, and SQLite3.

We can now use ``db`` as query factory, using any of ``select``, ``insert``,
``update`` or ``delete`` as methods::

  departments = db.select('departments', ['name', 'manager_id'])

Since it's common to use only a single database in your application, you can
set the global default engine for the module like so::

  gesundheit.defaultEngine = db
  # This is now equivalent to db.select(...)
  gesundheit.select('departments', ['name', 'manager_id'])

.. _Any-DB: https://github.com/grncdr/node-any-db

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

*(This example also shows passing a list of fields to
:func:`~queries/index::SELECT` as the second parameter).*

Conversely, if you are using :meth:`queries/sud::SUDQuery.project` to return a
:class:`nodes::Projection` node, you can use :meth:`~nodes::Projection.as` to
return an aliased version of the node::

  q = select('departments')
  q.fields(q.p('manager_id').as('m_id'))

This also works with :class:`nodes::Relation` and :class:`nodes::SqlFunction`
instances (as returned by :func:`nodes::sqlFunction`).

.. rubric:: Footnotes

.. [#] Use :meth:`queries/base::BaseQuery.copy` if you want to generate
  multiple independent refinements from a single query instance.

.. [#] Queries can be rebound with :meth:`queries/base::BaseQuery.bind`, but
  this should only be used if you know what you're doing and why.

A quick note on async, errors and ``throw``
-------------------------------------------

**Gesundheit throws exceptions at pretty much every opportunity**. The only time
an error is returned to a callback or emitted via event emitter is when a query
is actually executed. Any error that gesundheit can detect at query building
time will cause an exception to be thrown. This keeps the query building API's
straightforward and synchronous, and means gesundheit can prevent your code from
continuing to run with an obviously broken query.

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

Start a select query with :func:`~queries/index::SELECT`::

    light_recliners = select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

Join another table with :meth:`~queries/select::SelectQuery.join`::

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

  men_with_light_recliners = select('chairs', ['chair_type', 'size'], ->
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
    .set({influential: true})     # SET tweeters.influential = true
    .where({followers: {gt: 1000}}) # WHERE tweeters.followers > 1000;
    .execute(function (err) { /* ... */ })

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

Engine API Reference
--------------------

.. automodule:: engine

Dialects
========

.. automodule:: dialects

Nodes
=============

.. automodule:: nodes
