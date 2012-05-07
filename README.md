# Oedipus: Sphinx 2 Search Client for Ruby

Oedipus is a client for the Sphinx search engine (>= 2.0.2), with support for
real-time indexes and multi and multi-dimensional faceted searches.

It is not a clone of the PHP API, rather it is written from the ground up,
wrapping the SphinxQL API offered by searchd.  Nor is it a plugin for
ActiveRecord or DataMapper... though this will follow in separate gems (see
[oedipus-dm](https://github.com/d11wtq/oedipus-dm)).

Oedipus provides a level of abstraction in terms of the ease with which faceted
search may be implemented, while remaining light and simple.

Data structures are managed using core ruby data types (Array and Hash), ensuring
simplicity and flexibilty.

The current development focus is on supporting realtime indexes, where data is
indexed from your application, rather than by running the indexer tool that comes
with Sphinx.  You may use indexes that are indexed with the indexer tool, but
Oedipus does not (yet) provide wrappers for indexing that data via ruby [1].

## Dependencies

  * ruby >= 1.9
  * sphinx >= 2.0.2
  * mysql dev libs >= 4.1

## Installation

Via rubygems:

```
gem install oedipus
```

## Usage

The following features are all currently implemented.

### Connecting to Sphinx

``` ruby
require "oedipus"

sphinx = Oedipus.connect('localhost:9306') # sphinxql host
```

### Inserting (real-time indexes)

``` ruby
sphinx[:articles].insert(
  7,
  title:     "Badgers in the wild",
  body:      "A big long wodge of text",
  author_id: 4,
  views:     102
)
```

### Replacing (real-time indexes)

``` ruby
sphinx[:articles].replace(
  7,
  title:     "Badgers in the wild",
  body:      "A big long wodge of text",
  author_id: 4,
  views:     102
)
```

### Updating (real-time indexes)

``` ruby
sphinx[:articles].update(7, views: 103)
```

### Deleting (real-time indexes)

``` ruby
sphinx[:articles].delete(7)
# => true
```

### Fetching a known document (by ID)

``` ruby
record = sphinx[:articles].fetch(7)
# => { id: 7, views: 984, author_id: 3 }
```

### Fulltext searching

You perform queries by invoking `#search` on the index.

Oedipus makes no attempt to provide an abstraction layer for the fulltext
query itself.  I believe this would not be flexible enough.  Sphinx fulltext
queries are extremely featureful, very dense and concise; a ruby solution
would only be lengthier and harder to understand, IMHO.  Perhaps such an
abstraction could be provided by a separate gem.


``` ruby
results = sphinx[:articles].search("badgers", limit: 2)

# Meta deta indicates the overall number of matched records, while the ':records'
# array contains the actual data returned.
# 
# => {
#   total_found: 987,
#   time:        0.000,
#   keywords:  [ "badgers" ],
#   docs:      { "badgers" => 987 },
#   records:     [
#     { id: 7,  author_id: 4, views: 102 },
#     { id: 11, author_id: 6, views: 23 }
#   ]
# }
```

### Fetching only specific attributes

``` ruby
sphinx[:articles].search(
  "example",
  attrs: [:id, :views]
)
```

### Fetching additional attributes (including expressions)

Any valid field expression may be fetched.  Be sure to alias it if you want to order by it.

``` ruby
sphinx[:articles].search(
  "example",
  attrs: [:*, "WEIGHT() AS wgt"]
)
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
  views: -Float::INFINITY..100
)

sphinx[:articles].search(
  "example",
  views: Oedipus.lte(100)
)

# greater than
sphinx[:articles].search(
  "example",
  views: 100...Float::INFINITY
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

### Ordering

``` ruby
sphinx[:articles].search("badgers", order: { views: :asc })
```

Special handling is done for ordering by relevance.

``` ruby
sphinx[:articles].search("badgers", order: { relevance: :desc })
```

In the above case, Oedipus explicity adds `WEIGHT() AS relevance` to the `:attrs`
option.  You can manually set up the relevance sort if you wish to name the weighting
attribute differently.

### Limits and offsets

Note that Sphinx applies a limit of 20 by default, so you probably want to specify
a limit yourself.  You are bound by your `max_matches` setting in sphinx.conf.

Note that the meta data will still indicate the actual number of results that matched;
you simply get a smaller collection of materialized records.

``` ruby
sphinx[:articles].search("bobcats", limit: 50)
sphinx[:articles].search("bobcats", limit: 50, offset: 150)
```

### Faceted searching

A faceted search takes a base query and a set of additional queries that are
variations on it.  Oedipus makes this simple by allowing your facets to inherit
from the base query.

Oedipus allows you to replace '%{query}' in your facets with whatever was in the
original query.  This can be useful if you want to provide facets that only
perform the search in the title of the document (`"@title (%{query})"`) for
example.

Each facet is given a key, which is used to reference it in the results.  This
key is any arbitrary object that can be used as a key in a ruby Hash.  You may,
for example, use domain-specific objects as keys.

Sphinx optimizes the queries by figuring out what the common parts are.  Currently
it does two optimizations, though in future this will likely improve further, so
using this technique to do your faceted searches is the correct approach.

``` ruby
results = sphinx[:articles].search(
  "badgers",
  facets: {
    popular:         { views: 100..10000 },
    also_farming:    "%{query} & farming",
    popular_farming: ["%{query} & farming", views: 100..10000 ]
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
#     also_farming: {
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

#### Multi-dimensional faceted search

If you can add facets to the root query, how about adding facets to the facets
themselves?  Easy:

``` ruby
results = sphinx[:articles].search(
  "badgers",
  facets: {
    popular: {
      views:  100..10000,
      facets: {
        in_title: "@title (%{query})"
      }
    }
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
#       records: [ ... ],
#       facets: {
#         in_title: {
#           total_found: 24,
#           time: 0.000,
#           records: [ ... ]
#         }
#       }
#     }
#   }
# }
```

In the above example, the nested facet `:in_title` inherits the default
parameters from the facet `:popular`, which inherits its parameters from
the root query.  The result is a search for "badgers" limited only to the
title, with views between 100 and 10000.

There is no limit imposed in Oedipus for how deeply facets can be nested.

### General purpose multi-search

If you want to execute multiple queries in a batch that are not related to each
other (which would be a faceted search), then you can use `#multi_search`.

You pass a Hash of keyed-queries and get a Hash of keyed-resultsets.

``` ruby
results = sphinx[:articles].multi_search(
  badgers: ["badgers", limit: 30],
  frogs:   "frogs & wetlands",
  rabbits: ["rabbits | burrows", view_count: 20..100]
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

## Running the specs

There are both unit tests and integration tests in the specs/ directory.  By default they
will both run, but in order for the integration specs to work, you need a locally
installed copy of [Sphinx] [2].  You then execute the specs as follows:

    SEARCHD=/path/to/bin/searchd bundle exec rake spec

If you don't have Sphinx installed locally, you cannot run the integration specs (they need
to write config files and start and stop sphinx internally).

To run the unit tests alone, without the need for Sphinx:

    bundle exec rake spec:unit

If you have made changes to the C extension, those changes will be compiled and installed
(to the lib/ directory) before the specs are run.

You may also compile the C extension and run the specs separately, if you prefer:

    bundle exec rake compile
    bundle exec rspec spec/unit/

### Footnotes

  [1]: In practice I find such an abstraction not to be very useful, as it assumes a single-server setup

  [2]: You can build a local copy of sphinx without installing it on the system:

    cd sphinx-2.0.4/
    ./configure
    make

  The searchd binary will be found in /path/to/sphinx-2.0.4/src/searchd.

## Future Plans

  * Integration ActiveRecord (DataMapper support has already been added)
  * Support for re-indexing non-realtime indexes from ruby code
  * Distributed index support (sharding writes between indexes)
  * Make C extension optional and provide an implementation in pure-ruby
  * Query translation layer for Lucene-style AND/OR/NOT and attribute:value interpretation
  * Fulltext query sanitization for unsafe user input (e.g. @@missing field)

## Copyright and Licensing

Refer to the LICENSE file for details.
