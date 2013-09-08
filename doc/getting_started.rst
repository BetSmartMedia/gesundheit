Getting Started
===============

Installation
------------

`gesundheit` is installed via npm just as you'd expect::

   npm install --save gesundheit

In addition to `gesundheit` itself, you will need to install any database
drivers you plan on using::

   npm install --save pg mysql
   npm install --save-dev sqlite3


Creating a Query object
-----------------------

The main interface for building queries with `gesundheit` are the query manager
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
`bound` to an engine when they are first created, and will rely on that engine
when asked to render and/or execute. [#]_

.. _engine-usage-example:

Using a real database
---------------------

So far, we have been using the built-in ``fake`` engine, which does nothing
but render SQL strings. In order to use a real database, we need to create our
own engine object to use::

  var gesundheit = require('gesundheit')

  var db = gesundheit.engine('postgres://localhost/test')

The database URL above can point to any database supported by Any-DB_, which
includes MySQL, Postgres, and SQLite3.

The `engine` we just created (named ``db``) is a query factory. We can create
queries using ``select``, ``insert``, ``update`` or ``delete`` as methods::

  var departments = db.select('departments', ['name', 'manager_id'])

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

Conversely, if you are using :meth:`queries/sud::SUDQuery.column` to return a
:class:`nodes::Column` node, you can use :meth:`~nodes::Column.as` to
return an aliased version of the node::

  var q = select('departments')
  q.fields(q.c('manager_id').as('m_id'))

This also works with :class:`nodes::Relation` and :class:`nodes::SqlFunction`
instances (as returned by :func:`nodes::sqlFunction`).

.. rubric:: Footnotes

.. [#] Use :meth:`queries/base::BaseQuery.copy` if you want to generate
  multiple independent refinements from a single query instance.

.. [#] Actually, queries can be rebound with :meth:`queries/base::BaseQuery.bind`,
  but this should only be used if you know what you're doing and why.

A quick note on async, errors and ``throw``
-------------------------------------------

**Gesundheit throws exceptions at pretty much every opportunity**. The only time
an error is returned to a callback or emitted via event emitter is when a query
is actually executed. Any error that `gesundheit` can detect at query building
time will cause an exception to be thrown. This keeps the query building API's
straightforward and synchronous, and means `gesundheit` can prevent your code from
continuing to run with an obviously broken query.
