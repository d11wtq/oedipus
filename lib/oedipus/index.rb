# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Representation of a search index for querying.
  class Index
    attr_reader :name
    attr_reader :attributes

    # Initialize the index named +name+ on the connection +conn+.
    #
    # @param [Symbol] name
    #   the name of an existing index in sphinx
    #
    # @param [Connection] conn
    #   an instance of Oedipus::Connection for querying
    def initialize(name, conn)
      @name       = name.to_sym
      @conn       = conn
      @attributes = reflect_attributes
      @builder    = QueryBuilder.new(name, conn)
    end

    # Insert the record with the ID +id+.
    #
    # @example
    #   index.insert(42, :title => "example", :views => 22)
    #
    # @param [Integer] id
    #   the unique ID of the document in the index
    #
    # @param [Hash] hash
    #   a symbol-keyed hash of data to insert
    #
    # @return [Hash]
    #   a copy of the inserted record
    def insert(id, hash)
      data = Hash[
        [:id, *hash.keys.map(&:to_sym)].zip \
        [id,  *hash.values.map { |v| String === v ? @conn.quote(v) : v }]
      ]
      @conn.execute("INSERT INTO #{name} (#{data.keys.join(', ')}) VALUES (#{data.values.join(', ')})")
      attributes.merge(data.select { |k, _| attributes.key?(k) })
    end

    def search(*args)
      raise ArgumentError, "Wrong number of arguments (#{args.size} for 1..2)" unless (1..2) === args.size

      query, attrs = case args.first
        when String then [args[0], args[1] || {}]
        when Hash   then ["", args[0]]
        else raise ArgumentError, "Invalid argument type #{args.first.class} for argument 0"
      end

      results = @conn.execute(@builder.sql(query, attrs))
      meta    = @conn.execute("SHOW META")

      # FIXME: This needs optimizing
      {}.tap do |r|
        meta.each do |k, v|
          r[k.to_sym] = case k
            when 'total', 'total_found' then Integer(v)
            when 'time'                 then Float(v)
            else v
          end
        end

        r[:records] = []

        results.each_hash do |hash|
          r[:records] << Hash[hash.keys.map(&:to_sym).zip(hash.map { |k, v| cast(k, v) })]
        end
      end
    end

    private

    def cast(key, value)
      case attributes[key.to_sym]
      when Fixnum then Integer(value)
      else value
      end
    end

    def reflect_attributes
      rs = @conn.execute("DESC #{name}")
      {}.tap do |attrs|
        rs.each_hash do |row|
          case row['Type']
          when 'uint', 'integer' then attrs[row['Field'].to_sym] = 0
          when 'string'          then attrs[row['Field'].to_sym] = ""
          end
        end
      end
    end
  end
end
