# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  class QueryBuilder
    def initialize(index_name, conn)
      @index_name = index_name
      @conn       = conn
    end

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
      exprs << "MATCH(#{@conn.quote(query)})" unless query.empty?
      "WHERE " << exprs.join(" AND ") if exprs.any?
    end

    def limits(filters)
      "LIMIT #{filters[:offset].to_i}, #{filters[:limit].to_i}" if filters.key?(:limit)
    end
  end
end
