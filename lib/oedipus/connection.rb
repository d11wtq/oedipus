# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "mysql"

module Oedipus
  # Provides an interface for talking to SphinxQL.
  class Connection
    # Instantiate a new Connection to a SphinxQL host.
    #
    # @param [Hash]
    #   a Hash containing :host and :port
    #
    # The connection will be established on initialization.
    def initialize(options)
      @conn = Oedipus::Mysql.new(options[:host], options[:port])
    end

    # Acess a specific index for querying.
    #
    # @param [String] index_name
    #   the name of an existing index in Sphinx
    #
    # @return [Index]
    #   an index that can be queried
    def [](index_name)
      Index.new(index_name, self)
    end

    # Execute one or more queries in a batch.
    #
    # Queries should be separated by semicolons.
    # Results are returned in a 2-dimensional array.
    #
    # @param [String] sql
    #   one or more SphinxQL statements, separated by semicolons
    #
    # @return [Array]
    #   an array of arrays, containing the returned records
    def multi_query(sql)
      @conn.query(sql)
    end

    # Execute a single read query.
    #
    # @param [String] sql
    #   a single SphinxQL statement
    #
    # @return [Array]
    #   an array of Hashes containing the matched records
    def query(sql)
      @conn.query(sql).first
    end

    # Execute a non-read query.
    #
    # @param [String] sql
    #   a SphinxQL query, such as INSERT or REPLACE
    #
    # @return [Fixnum]
    #   the number of affected rows
    def execute(sql)
      @conn.execute(sql)
    end

    def quote(v)
      case v
      when Numeric then v
      else "'#{::Mysql.quote(v.to_s)}'"
      end
    end
  end
end
