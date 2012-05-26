# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Provides an interface for talking to SphinxQL.
  #
  # Currently this class wraps a native mysql extension.
  class Connection
    attr_reader :options

    # Instantiate a new Connection to a SphinxQL host.
    #
    # @param [String] server
    #   a 'hostname:port' string
    #
    # @param [Hash] options
    #   a Hash containing :host and :port
    #
    # The connection will be established on initialization.
    #
    # The underlying implementation uses a thread-safe connection pool.
    def initialize(options)
      @options =
        if options.kind_of?(String)
          Hash[ [:host, :port].zip(options.split(":")) ]
        else
          options.dup
        end.tap { |o| o[:port] = o[:port].to_i }

      @pool = Pool.new(
        host: @options[:host],
        port: @options[:port],
        size: @options.fetch(:pool_size, 8),
        ttl:  60
      )

      assert_valid_pool unless @options[:verify] == false
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

    alias_method :index, :[]

    # Execute one or more queries in a batch.
    #
    # Queries should be separated by semicolons.
    # Results are returned in a 2-dimensional array.
    #
    # @param [String] sql
    #   one or more SphinxQL statements, separated by semicolons
    #
    # @param [Object...] bind_values
    #   values to be substituted in place of '?' in the query
    #
    # @return [Array]
    #   an array of arrays, containing the returned records
    #
    # Note that SphinxQL does not support prepared statements.
    def multi_query(sql, *bind_values)
      @pool.acquire { |conn| conn.query(sql, *bind_values) }
    end

    # Execute a single read query.
    #
    # @param [String] sql
    #   a single SphinxQL statement
    #
    # @param [Object...] bind_values
    #   values to be substituted in place of '?' in the query
    #
    # @return [Array]
    #   an array of Hashes containing the matched records
    #
    # Note that SphinxQL does not support prepared statements.
    def query(sql, *bind_values)
      @pool.acquire { |conn| conn.query(sql, *bind_values).first }
    end

    # Execute a non-read query.
    #
    # @param [String] sql
    #   a SphinxQL query, such as INSERT or REPLACE
    #
    # @param [Object...] bind_values
    #   values to be substituted in place of '?' in the query
    #
    # @return [Fixnum]
    #   the number of affected rows
    #
    # Note that SphinxQL does not support prepared statements.
    def execute(sql, *bind_values)
      @pool.acquire { |conn| conn.execute(sql, *bind_values) }
    end

    # Disconnect from the remote host.
    #
    # There is no need to explicitly re-connect after invoking this;
    # connections are re-established as needed.
    def close
      @pool.dispose
    end

    private

    def assert_valid_pool
      @pool.acquire { nil }
    end
  end
end
