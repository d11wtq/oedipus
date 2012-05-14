# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  class Connection
    module Registry
      # Connect to Sphinx running SphinxQL.
      #
      # Connections are cached for re-use.
      #
      # @example
      #   c = Oedipus.connect("127.0.0.1:9306")
      #   c = Oedipus.connect(host: "127.0.0.1", port: 9306)
      #   c = Oedipus.connect("127.0.0.1:9306", :dist_host)
      #
      # @param [String|Hash] server
      #   a 'hostname:port' string, or
      #   a Hash with :host and :port keys
      #
      # @param [Object] key
      #   an optional name for the connection
      #
      # @return [Connection]
      #   a client connected to SphinxQL
      def connect(options, key = :default)
        connections[key] = Connection.new(options)
      end

      # Lookup an already connected connection.
      #
      # @example
      #   c = Oedipus.connection
      #   c = Oedipus.connection(:dist_host)
      #
      # @param [Object] key
      #   an optional name for the connection
      #
      # @return [Connection]
      #   a client connected to SphinxQL
      def connection(key = :default)
        raise ArgumentError, "Connection #{key} is not defined" unless connections.key?(key)
        connections[key]
      end

      def connections
        @connections ||= {}
      end
    end
  end
end
