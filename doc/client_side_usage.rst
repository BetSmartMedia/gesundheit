Client-side usage - Experimental
================================

Starting with version 0.9, Gesundheit can be used in the browser with
`Browserify <https://github.com/substack/node-browserify>`_. There are also
precompiled standalone bundles (available on Github) that declare a
``gesundheit`` global variable.

Because it is not possible to connect directly to a database server over a
socket from the browser, queries created in the browser will need to be sent to
some sort of server-side component for execution.

Securely executing queries from untrusted sources
-------------------------------------------------

The idea of executing arbitrary SQL statements sent to your web-app should be
setting off all kinds of alarm bells. Luckily, Gesundheit provides a better
alternative. Instead of sending queries as an opaque string, a browser-based
client instead sends a serialized AST. On the server side this datastructure
is unmarshalled back into a Gesundheit query object.

This is an improvement over arbitrary text, but it's still not really providing
any `security`; A user can construct an awful lot of malicious queries using
Gesundheit.

The next layer of security is pluggable via the ``visitor`` argument to
``gesundheit.unmarshaller(visitor, data)``. This ``visitor`` object can
interact with and/or abort the unmarshalling process. For example::

    var allowedTables = ['free_for_all', 'delete_my_records'];
    var checkTableName = {
      before: function (nodeData, path) {
        if (nodeData._type == 'Relation'
            && allowedTables.indexOf(nodeData.value) == -1)
        {
          throw new Error("Access denied");
        }
      }
    }

    var userInput = JSON.parse(arbitraryString);
    var query = gesundheit.unmarshaller(checkTableNames, userInput);

If a query attempts to access any table that is not listed in ``allowedTables``
an error will be thrown. The above could also be written using the ``after``
hook::

    var allowedTables = ['free_for_all', 'delete_my_records'];
    var checkTableName = {
      after: function (node, path) {
        if (node instanceof gesundheit.nodes.Relation)
            && allowedTables.indexOf(node.value) == -1)
        {
          throw new Error("Access denied");
        }
      }
    }

Missing Batteries
-----------------

This approach currently leaves most of the hard work up to the end user. Several
additional projects are envisaged that will make this much easier to use.

    1. A "compiler" of sorts that creates a visitor object using a declarative
           access policy description.
           
    2. An engine implementation sends queries over HTTP.

    3. A server-side "bridge" component that can handle HTTP requests from #2
           and enforce an access policy using #1.

Each of these could be published separately from Gesundheit itself, which is
already quite large.
