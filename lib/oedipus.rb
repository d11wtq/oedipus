# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "oedipus/version"

require "oedipus/oedipus"

require "oedipus/comparison"
require "oedipus/comparison/equal"
require "oedipus/comparison/not_equal"
require "oedipus/comparison/between"
require "oedipus/comparison/outside"
require "oedipus/comparison/in"
require "oedipus/comparison/not_in"
require "oedipus/comparison/gte"
require "oedipus/comparison/gt"
require "oedipus/comparison/lte"
require "oedipus/comparison/lt"
require "oedipus/comparison/not"
require "oedipus/comparison/shortcuts"

require "oedipus/query_builder"

require "oedipus/connection"

require "oedipus/index"

module Oedipus
  extend Comparison::Shortcuts

  class << self
    # Connect to Sphinx running SphinxQL.
    #
    # @example
    #   c = Oedipus.connect("localhost:9306")
    #   c = Oedipus.connect(host: "localhost", port: 9306)
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
      Connection.new(options)
    end
  end
end
