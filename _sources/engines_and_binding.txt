Engines and Binding
====================

A gesundheit query must be "bound" to an "engine" to render and/or execute. For
apps that deal with a single database, you can simply create an engine instance
during application startup, assign it to ``gesundheit.defaultEngine`` and not
have to think about binding after that.

Engine API Reference
--------------------

.. automodule:: engine


