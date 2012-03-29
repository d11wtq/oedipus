# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "oedipus/version"
require "oedipus/query_builder"
require "oedipus/connection"
require "oedipus/index"
require "oedipus/mysql/client"

module Oedipus
  class << self
    # Connect to Sphinx running SphinxQL.
    #
    # @example
    #   c = Oedipus.connect("localhost:9306")
    #   c = Oedipus.connect(:host => "localhost", :port => 9306)
    #
    # @param [String] server
    #   a 'hostname:port' string
    #
    # @param [Hash] options
    #   a Hash with :host and :port keys
    #
    # @return [Connection]
    #   a client connected to SphinxQL
    def connect(options)
      # TODO: Add pooling
      Connection.new(
        options.kind_of?(String) ?
          Hash[ [:host, :port].zip(options.split(":")) ] :
          options
      )
    end
  end
end
