# Oedipus: Sphinx 2 Search Client for Ruby

Oedipus is a client for the Sphinx search engine (>= 2.0.2), with support for
real-time indexes and multi and/or faceted searches.

It is not a clone of the PHP API, rather it is written from the ground up,
wrapping the SphinxQL API offered by searchd.  Nor is it a plugin for
ActiveRecord or DataMapper... though this is planned in separate gems.

It will provide some higher level of abstraction in terms of the ease with
which faceted search may be implemented, though it will remain light and simple.

## Current Status

This gem is in development.  It is not ready for production use.  I work for
a company called Flippa.com, which currently implements faceted search in a PHP
part of the website, using a slightly older version of Sphinx with lesser
support for SphinxQL.  Once a month the developers at Flippa are given three days
to work on a project of their own choice.  This is my 'Triple Time' project.

I anticipate another week or two of development before I can consider this project
production-ready.

## Usage

Not all of the following features are currently implemented, but the interface
style is as follows.

``` ruby
require "oedipus"

sphinx = Oedipus.connect('localhost:9306') # sphinxql host

# insert a record into the 'articles' real-time index
record = sphinx[:articles].insert(
  7,
  title:     "Badgers in the wild",
  body:      "A big long wodge of text",
  author_id: 4,
  views:     102
)
# The attributes (but not the indexed fields) are returned
# => { id: 7,  author_id: 4, views: 102 }

# updating a record
record = sphinx[:articles].update(7, views: 103)
# The new attributes (but not the indexed fields) are returned
# => { id: 7,  author_id: 4, views: 103 }

# deleting a record
sphinx[:articles].delete(7)
# => true

# searching the index
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

# using attribute filters
results = sphinx[:articles].search(
  "example",
  author_id: 7
)
# => (the same results, filtered by author)

# performing a faceted search
results = sphinx[:articles].facted_search(
  "badgers",
  facets: {
    popular:         { views: 100..10000 },
    farming:         "farming",
    popular_farming: ["farming", { views: 100..10000 } ]
  }
)
# The main results are returned in the ':records' array, and all the facets in
# the ':facets' Hash.
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
# 
# When performing a faceted search, the primary search is used as the basis for
# each facet, so they can be considered refinements.

# performing a mutli-search
results = sphinx[:articles].multi_search(
  badgers: ["badgers", { limit: 30 }],
  frogs:   "frogs AND wetlands",
  rabbits: ["rabbits OR burrows", { view_count: 20..100 }]
)
# The results are returned in a 2-dimensional Hash, keyed as sent in the query
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
# 
# Unlike with a faceted search, the queries in a multi-search do not have to be
# related to one another.
```

## Future Plans

I plan to release gems for integration with DataMapper and ActiveRecord.  DataMapper
first, since that's what we use.

I also intend to remove ruby-mysql from the dependencies, as it doesn't perfectly fit
the needs of SphinxQL.  I will be implementing the limited subset of the MySQL protocol
by hand (which is not as big a deal as it sounds).

## Copyright and Licensing

Refer to the LICENSE file for details.
