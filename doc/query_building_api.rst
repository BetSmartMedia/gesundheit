Query Building API reference
============================

.. automodule:: queries/index

BaseQuery
---------

.. automodule:: queries/base

Insert
------

Examples
^^^^^^^^

Insert a single row::

    var insert = require('gesundheit').insert

    insert('people', {name: 'Jerry'}).execute(function (err, result) {
        // Handle err
    })


Add multiple rows to a single insert::

    var q = insert('people', ['name'])
    q.addRows([
      ['Jerry'],
      ['Joey'],
      ['Jimbob']
    ])
    q.execute(function (err, result) {
        // Handle err
    })

API
^^^

.. automodule:: queries/insert

SUDQuery
--------

.. automodule:: queries/sud


Select
------

Examples
^^^^^^^^

Start a select query with :func:`~queries/index::SELECT`::

    var select = require('gesundheit').select
    var lightRecliners = select('chairs', ['chair_type', 'size'])
      .where({chair_type: 'recliner', weight: {lt: 25}})

Join another table with :meth:`~queries/select::SelectQuery.join`::

    var malesWithLightRecliners = lightRecliners.copy()
      .join("people", {
        on: {chair_id: light_recliners.column('chairs.id')},
        fields: ['name']
      })
      .where({sex: 'M'})

Note that joining a table "focuses" it, so ``.where({sex: 'M'})`` refers to the
``people.sex`` column. You can avoid this implicit behaviour by using full
column names (e.g. ``'chairs.id'``) or switching focus back to a previous table
using :meth:`queries/select::SelectQuery.focus`::

  men_with_light_recliners.focus('chairs')

Lets order the results by ``chairs.weight`` and get the top 5::

  men_with_light_recliners
    .order(weight: 'ASC)
    .limit(5)

The entire query can also be written without needing a temp variable by using
the third parameter to select (a callback function that will be passed to
:meth:`queries/base::BaseQuery.visit`)::

  men_with_light_recliners = select 'chairs', ['chair_type', 'size'], function (q) {
    q.where({chair_type: 'recliner', weight: {lt: 25}})
    q.join("people", {
      on: {chair_id: q.column('chairs.id')},
      fields: ['name']
    })
    q.where({gender: 'M'})
    q.order({'chairs.weight': 'ASC'})
    q.limit(5)
  })

API
^^^

.. automodule:: queries/select

Update
------

Examples
^^^^^^^^

Updating rows that match a condition::

  update('tweeters')                # UPDATE tweeters
    .set({influential: true})       # SET tweeters.influential = true
    .where({followers: {gt: 1000}}) # WHERE tweeters.followers > 1000;
    .execute(function (err, res) { /* ... */ })

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

