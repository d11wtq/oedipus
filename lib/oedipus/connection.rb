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
    class << self
      # Quote a value (of any type) for use in SphinxQL.
      #
      # @param [Object] v
      #   the value to quote
      #
      # @return [Object]
      #   the safe value
      #
      # Note that single quotes are added to strings.
      def quote(v)
        require "bigdecimal" unless defined? BigDecimal
        case v
        when BigDecimal, Rational, Complex
          v.to_f
        when Numeric
          v
        when NilClass
          "NULL"
        else
          "'#{escape_str(v.to_s)}'"
        end
      end

      # Escape a string, without adding enclosing quotes.
      #
      # @param [String] str
      #   the unsafe input string
      #
      # @return [String]
      #   a safe string for use in SphinxQL
      def escape_str(str)
        str.gsub(/[\0\n\r\\\'\"\x1a]/) do |s|
          case s
          when "\0"   then "\\0"
          when "\n"   then "\\n"
          when "\r"   then "\\r"
          when "\x1a" then "\\Z"
          else "\\#{s}"
          end
        end
      end
    end

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
      options = options.kind_of?(String) ?
        Hash[ [:host, :port].zip(options.split(":")) ] :
        options

      @pool = Pool.new(
        host: options[:host],
        port: options[:port].to_i,
        size: options.fetch(:pool_size, 8),
        ttl:  60
      )

      assert_valid_pool
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
    #
    # Note that SphinxQL does not support prepared statements.
    def multi_query(sql)
      @pool.acquire { |conn| conn.query(sql) }
    end

    # Execute a single read query.
    #
    # @param [String] sql
    #   a single SphinxQL statement
    #
    # @return [Array]
    #   an array of Hashes containing the matched records
    #
    # Note that SphinxQL does not support prepared statements.
    def query(sql)
      @pool.acquire { |conn| conn.query(sql).first }
    end

    # Execute a non-read query.
    #
    # @param [String] sql
    #   a SphinxQL query, such as INSERT or REPLACE
    #
    # @return [Fixnum]
    #   the number of affected rows
    #
    # Note that SphinxQL does not support prepared statements.
    def execute(sql)
      @pool.acquire { |conn| conn.execute(sql) }
    end

    private

    def assert_valid_pool
      @pool.acquire { nil }
    end
  end
end
