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
        [id,  *hash.values.map { |v| @conn.quote(v) }]
      ]
      @conn.execute("INSERT INTO #{name} (#{data.keys.join(', ')}) VALUES (#{data.values.join(', ')})")
      attributes.merge(data.select { |k, _| attributes.key?(k) })
    end

    # Perform a search on the index.
    #
    # Either one or two arguments may be passed, with either one being mutually
    # optional.
    #
    # @example Fulltext search
    #   index.search("cats AND dogs")
    #
    # @example Fulltext search with attribute filters
    #   index.search("cats AND dogs", author_id: 57)
    #
    # @example Attribute search only
    #   index.search(author_id: 57)
    #
    # @param [String] query
    #   a fulltext query
    #
    # @param [Hash] filters
    #   attribute filters, limits, sorting and other options
    #
    # @return [Hash]
    #   a Hash containing meta data, with the records in :records
    def search(*args)
      multi_search(main: args)[:main]
    end

    # Perform a a batch search on the index.
    #
    # A Hash of queries is passed, whose keys are used to collate the results in
    # the return value.
    #
    # Each query may either by a string (fulltext search), a Hash (attribute search)
    # or an array containing both.  In other words, the same arguments accepted by
    # the #search method.
    #
    # @example
    #   index.multi_search(
    #     cat_results: ["cats", { author_id: 57 }],
    #     dog_results: ["dogs", { author_id: 57 }]
    #   )
    #
    # @param [Hash] queries
    #   a hash whose keys map to queries
    #
    # @return [Hash]
    #   a Hash whose keys map 1:1 with the input Hash, each element containing the
    #   same results as those returned by the #search method.
    def multi_search(queries)
      unless queries.kind_of?(Hash)
        raise ArgumentError, "Argument must be a Hash of named queries (#{queries.class} given)"
      end

      rs = @conn.query(
        queries.map { |key, args|
          [@builder.sql(*extract_query_data(*args)), "SHOW META"]
        }.flatten.join(";\n")
      )

      {}.tap do |result|
        queries.keys.each do |key|
          records, meta = rs.shift, rs.shift
          result[key] = meta_to_hash(meta).tap do |r|
            r[:records] = records.map { |hash|
              hash.inject({}) { |o, (k, v)| o.merge!(k.to_sym => cast(k, v)) }
            }
          end
        end
      end
    end

    private

    def meta_to_hash(meta)
      {}.tap do |hash|
        meta.each do |m|
          n, v = m.values
          case n
          when "total_found", "total" then hash[n.to_sym] = v.to_i
          when "time"                 then hash[:time] = v.to_f
          when /\Adocs\[\d+\]\Z/      then (hash[:docs] ||= []).tap { |a| a << v.to_i }
          when /\Ahits\[\d+\]\Z/      then (hash[:hits] ||= []).tap { |a| a << v.to_i }
          when /\Akeyword\[\d+\]\Z/   then (hash[:keywords] ||= []).tap { |a| a << v }
          else hash[n.to_sym] = v
          end
        end
      end
    end

    def extract_query_data(*args)
      unless (1..2) === args.size
        raise ArgumentError, "Wrong number of arguments (#{args.size} for 1..2)"
      end

      case args[0]
      when String then [args[0], args.fetch(1, {})]
      when Hash   then ["", args[0]]
      else raise ArgumentError, "Invalid argument type #{args.first.class} for argument 0"
      end
    end

    def cast(key, value)
      case attributes[key.to_sym]
      when Fixnum then Integer(value)
      else value
      end
    end

    def reflect_attributes
      {}.tap do |attrs|
        @conn.query("DESC #{name}").first.each do |row|
          case row['Type']
          when 'uint', 'integer' then attrs[row['Field'].to_sym] = 0
          when 'string'          then attrs[row['Field'].to_sym] = ""
          end
        end
      end
    end
  end
end
