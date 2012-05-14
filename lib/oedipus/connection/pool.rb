# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "thread"

module Oedipus
  class Connection
    # Provides a thread-safe pool of connections, with a specified TTL.
    class Pool
      # Initialize a new connection pool with the given options.
      #
      # @param [Hash] options
      #   configuration for the pool
      #
      # @option [String] host
      #   the host to use when allocating new connections
      #
      # @option [Fixnum] port
      #   the port to use when allocating new connections
      #
      # @option [Fixnum] size
      #   the maximum number of connections (defaults to 8)
      #
      # @option [Fixnum] ttl
      #   the length of time for which any given connection should live
      def initialize(options)
        @host = options[:host]
        @port = options[:port]

        @size = options.fetch(:size, 8)
        @ttl  = options.fetch(:ttl, 60)

        @available = []
        @used      = {}
        @expiries  = {}
        @condition = ConditionVariable.new
        @lock      = Mutex.new

        sweeper
      end

      # Acquire a connection from the pool, for the duration of a block.
      #
      # The release of the connection is done automatically.
      #
      # @yields [Oedipus::Mysql]
      #   a connection object
      def acquire
        instance = nil
        begin
          @lock.synchronize do
            if instance = @available.pop
              @used[instance] = instance
            elsif @size > (@available.size + @used.size)
              instance = new_instance
            else
              @condition.wait(@lock)
            end
          end
        end until instance

        yield instance
      ensure
        release(instance)
      end

      # Dispose all connections in the pool.
      #
      # Waits until all connections have finished processing current queries
      # and then releases them.
      def dispose
        begin
          @lock.synchronize do
            while instance = @available.pop
              instance.close
            end

            @condition.wait(@lock) if @used.size > 0
          end
        end until empty?
      end

      # Returns true if the pool is currently empty.
      #
      # @return [Boolean]
      #   true if no connections are pooled, false otherwise
      def empty?
        @lock.synchronize { @used.size == 0 && @available.size == 0 }
      end

      private

      def release(instance)
        @lock.synchronize do
          @available << @used.delete(instance) if instance
          @condition.broadcast
        end
      end

      def new_instance
        Oedipus::Mysql.new(@host, @port).tap do |instance|
          @used[instance]     = instance
          @expiries[instance] = Time.now + @ttl
        end
      end

      # Close connections past their ttl (runs in a new Thread)
      def sweeper
        Thread.new(@expiries, @available) do |exp, avail|
          loop do
            sleep 15
            @lock.synchronize {
              avail.each do |instance|
                if exp[instance] < Time.now
                  avail.delete(instance)
                  exp.delete(instance)
                  instance.close
                end
              end
            }
          end
        end
      end

    end
  end
end
