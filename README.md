# Oedipus: Sphinx 2 Search Client for Ruby

Oedipus is a client for the Sphinx search engine (>= 2.0.2), with support for
real-time indexes and multi and/or faceted searches.

It is not a clone of the PHP API, rather it is written from the ground up,
wrapping the SphinxQL API offered by searchd.  Nor is it a plugin for
ActiveRecord or DataMapper... though this will follow in separate gems.

Oedipus provides a level of abstraction in terms of the ease with which faceted
search may be implemented, while remaining light and simple.

Data structures are managed using core ruby data type (Array and Hash), ensuring
simplicity and flexibilty.

## Current Status

This gem is in development.  It is not ready for production use.  I work for
a company called Flippa.com, which currently implements faceted search in a PHP
part of the website, using a slightly older version of Sphinx with lesser
support for SphinxQL.  We want to move this search across to the ruby codebase
of the website, but are held back by ruby's lack of support for Sphinx 2.

Once a month the developers at Flippa are given three days to work on a project of
their own choice.  This is my 'Triple Time' project.

I anticipate another week or so of development before I can consider this project
production-ready.

## Dependencies

  * ruby (>= 1.9)
  * sphinx (>= 2.0.2)
  * mysql.h / client development libraries (>= 4.1)

The gem builds a small native extension for interfacing with mysql, as existing gems
either did not support multi-queries, or were too flaky (i.e. ruby-mysql) and I was
concerned about conflicts with any specific ORMs users may be using.  I will add
a pure-ruby option in due course (it requires implementing a relatively small subset
of the mysql 4.1/5.0 protocol).

## Usage

Not all of the following features are currently implemented, but the interface
style is as follows.

### Connecting to Sphinx

``` ruby
require "oedipus"

sphinx = Oedipus.connect('localhost:9306') # sphinxql host
```

### Inserting

``` ruby
record = sphinx[:articles].insert(
  7,
  title:     "Badgers in the wild",
  body:      "A big long wodge of text",
  author_id: 4,
  views:     102
)
# The attributes (but not the indexed fields) are returned
# => { id: 7,  author_id: 4, views: 102 }
```

### Updating

``` ruby
record = sphinx[:articles].update(7, views: 103)
# The new attributes (but not the indexed fields) are returned
# => { id: 7,  author_id: 4, views: 103 }
```

### Deleting

``` ruby
sphinx[:articles].delete(7)
# => true
```

### Fulltext searching

``` ruby
results = sphinx[:articles].search("badgers", limit: 2)

# Meta deta indicates the overall number of matched records, while the ':records'
# array contains the actual data returned.
# 
# => {
#   total_found: 987,
#   time:        0.000,
#   keyword[0]:  "badgers",
#   docs[0]:     987,
#   records:     [
#     { id: 7,  author_id: 4, views: 102 },
#     { id: 11, author_id: 6, views: 23 }
#   ]
# }
```

### Attribute filters

Result formatting is the same as for a fulltext search.  You can add as many
filters as you like.

``` ruby
# equality
sphinx[:articles].search(
  "example",
  author_id: 7
)

# less than or equal
sphinx[:articles].search(
  "example",
  views: -(1/0.0)..100
)

sphinx[:articles].search(
  "example",
  views: Oedipus.lte(100)
)

# greater than
sphinx[:articles].search(
  "example",
  views: 100...(1/0.0)
)

sphinx[:articles].search(
  "example",
  views: Oedipus.gt(100)
)

# not equal
sphinx[:articles].search(
  "example",
  author_id: Oedipus.not(7)
)

# between
sphinx[:articles].search(
  "example",
  views: 50..100
)

sphinx[:articles].search(
  "example",
  views: 50...100
)

# not between
sphinx[:articles].search(
  "example",
  views: Oedipus.not(50..100)
)

sphinx[:articles].search(
  "example",
  views: Oedipus.not(50...100)
)

# IN( ... )
sphinx[:articles].search(
  "example",
  author_id: [7, 22]
)

# NOT IN( ... )
sphinx[:articles].search(
  "example",
  author_id: Oedipus.not([7, 22])
)
```

### Faceted searching

A faceted search takes a base query and a set of additional queries that are
variations on it.  Oedipus makes this simple by allowing your facets to inherit
from the base query.

Each facet is given a name, which is used to reference them in the results.

Sphinx optimizes the queries by figuring out what the common parts are.

``` ruby
results = sphinx[:articles].facted_search(
  "badgers",
  facets: {
    popular:         { views: 100..10000 },
    farming:         "farming",
    popular_farming: ["farming", { views: 100..10000 } ]
  }
)
# => {
#   total_found: 987,
#   time: 0.000,
#   records: [ ... ],
#   facets: {
#     popular: {
#       total_found: 25,
#       time: 0.000,
#       records: [ ... ]
#     },
#     farming: {
#       total_found: 123,
#       time: 0.000,
#       records: [ ... ]
#     },
#     popular_farming: {
#       total_found: 2,
#       time: 0.000,
#       records: [ ... ]
#     }
#   }
# }
```

### General purpose multi-search

If you want to execute multiple queries in a batch that are not related to each
other (which is a faceted search), then you can use `#multi_search`.

You pass a Hash of named queries and get a Hash of named resultsets.

``` ruby
results = sphinx[:articles].multi_search(
  badgers: ["badgers", { limit: 30 }],
  frogs:   "frogs AND wetlands",
  rabbits: ["rabbits OR burrows", { view_count: 20..100 }]
)
# => {
#   badgers: {
#     ...
#   },
#   frogs: {
#     ...
#   },
#   rabbits: {
#     ...
#   }
# }
```

### Limits and offsets

Note that Sphinx applies a limit of 20 by default, so you probably want to specify
a limit yourself.  You are bound by your `max_matches` setting in sphinx.conf.

Note that the meta data will still indicate the actual number of results that matched;
you simply get a smaller collection of materialized records.

``` ruby
sphinx[:articles].search("bobcats", limit: 50)
sphinx[:articles].search("bobcats", limit: 50, offset: 150)
```

### Ordering

``` ruby
sphinx[:articles].search("badgers", order: { views: :asc })
```

## Future Plans

I plan to release gems for integration with DataMapper and ActiveRecord.  DataMapper
first, since that's what we use.

I also would like to implement the small subset of the MySQL protocol necessary for
communication with SphinxQL, instead of forcing users to use a native extension (though
still keep this as an option for those who have libmysql).

## Copyright and Licensing

Refer to the LICENSE file for details.
