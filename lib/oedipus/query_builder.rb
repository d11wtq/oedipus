# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Constructs SphinxQL queries from the internal Hash format.
  class QueryBuilder
    # Initialize a new QueryBuilder for +index_name+.
    #
    # @param [Symbol] index_name
    #   the name of the index being queried
    def initialize(index_name)
      @index_name = index_name
    end

    # Build a SphinxQL query for the fulltext search +query+ and filters in +filters+.
    #
    # @param [String] query
    #   the fulltext query to execute (may be empty)
    #
    # @param [Hash] filters
    #   additional attribute filters and other options
    #
    # @return [String]
    #   a SphinxQL query
    def sql(query, filters)
      [
        from,
        conditions(query, filters),
        limits(filters)
      ].join(" ")
    end

    private

    def from
      "SELECT * FROM #{@index_name}"
    end

    def conditions(query, filters)
      exprs = []
      exprs << "MATCH(#{Connection.quote(query)})" unless query.empty?
      "WHERE " << exprs.join(" AND ") if exprs.any?
    end

    def limits(filters)
      "LIMIT #{filters[:offset].to_i}, #{filters[:limit].to_i}" if filters.key?(:limit)
    end
  end
end
