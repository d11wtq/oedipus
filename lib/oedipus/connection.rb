# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "mysql"

# SphinxQL greets with charset number 0
Mysql::Charset::NUMBER_TO_CHARSET[0] = Mysql::Charset::COLLATION_TO_CHARSET["utf8_general_ci"]

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
      @conn = ::Mysql.new(options[:host], nil, nil, nil, options[:port], nil, ::Mysql::CLIENT_MULTI_STATEMENTS | ::Mysql::CLIENT_MULTI_RESULTS)
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

    def execute(sql)
      @conn.query(sql)
    end

    def quote(v)
      case v
      when Numeric then v
      else "'#{::Mysql.quote(v.to_s)}'"
      end
    end
  end
end
