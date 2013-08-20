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

    # Initialize the index named +name+ on the connection +conn+.
    #
    # @param [Symbol] name
    #   the name of an existing index in sphinx
    #
    # @param [Connection] conn
    #   an instance of Oedipus::Connection for querying
    def initialize(name, conn)
      @name    = name.to_sym
      @conn    = conn
      @builder = QueryBuilder.new(name)
    end

    # Insert the record with the ID +id+.
    #
    # @example
    #   index.insert(42, title: "example", views: 22)
    #
    # @param [Integer] id
    #   the unique ID of the document in the index
    #
    # @param [Hash] hash
    #   a symbol-keyed hash of data to insert
    #
    # @return [Fixnum]
    #   the number of rows inserted (currently always 1)
    def insert(id, hash)
      @conn.execute(*@builder.insert(id, hash))
    end

    # Update the record with the ID +id+.
    #
    # @example
    #   index.update(42, views: 25)
    #
    # @param [Integer] id
    #   the unique ID of the document in the index
    #
    # @param [Hash] hash
    #   a symbol-keyed hash of data to set
    #
    # @return [Fixnum]
    #   the number of rows updated (1 or 0)
    def update(id, hash)
      @conn.execute(*@builder.update(id, hash))
    end

    # Completely replace the record with the ID +id+.
    #
    # @example
    #   index.replace(42, title: "New title", views: 25)
    #
    # @param [Integer] id
    #   the unique ID of the document in the index
    #
    # @param [Hash] hash
    #   a symbol-keyed hash of data to insert
    #
    # @return [Fixnum]
    #   the number of rows inserted (currentl always 1)
    def replace(id, hash)
      @conn.execute(*@builder.replace(id, hash))
    end

    # Delete the record with the ID +id+.
    #
    # @example
    #   index.delete(42)
    #
    # @param [Integer] id
    #   the unique ID of the document in the index
    #
    # @return [Fixnum]
    #   the number of rows deleted (currently always 1 or 0)
    def delete(id)
      @conn.execute(*@builder.delete(id))
    end

    # Fetch a single document by its ID.
    #
    # Returns the Hash of attributes if found, otherwise nil.
    #
    # @param [Fixnum] id
    #   the ID of the document
    #
    # @return [Hash]
    #   the attributes of the record
    def fetch(id)
      search(id: id)[:records].first
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
    # When performing a faceted search, the base query is inherited by each facet, which
    # may override (or refine) the query.
    #
    # The results returned include a :facets key, containing the results for each facet.
    #
    # @example Performing a faceted search
    #   index.search(
    #     "cats | dogs",
    #     category_id: 7,
    #     facets: {
    #       popular: {views:        Oedipus.gt(150)},
    #       recent:  {published_at: Oedipus.gt(Time.now.to_i - 7 * 86400)}
    #     }
    #   )
    #
    # To perform an n-dimensional faceted search, add a :facets option to each
    # facet. Each facet will inherit from its immediate parent, which inerits
    # from its parent, up to the root query.
    #
    # @example Performing a n-dimensional faceted search
    #   index.search(
    #     "cats | dogs",
    #     facets: {
    #       popular: {
    #         views: Oedipus.gte(1000),
    #         facets: {
    #           in_title: "@title (%{query})"
    #         }
    #       }
    #     }
    #   )
    #
    # The results in a n-dimensional faceted search are returned with each set
    # of facet results in turn containing a :facets element.
    #
    # @param [String] query
    #   a fulltext query
    #
    # @param [Hash] options
    #   attribute filters, limits, sorting, facets and other options
    #
    # @option [Hash] facets
    #   variations on the main search to return nested in the result
    #
    # @option [Array] attrs
    #   attributes to fetch from the index, either as Symbols, or SphinxQL fragments
    #
    # @option [Hash] order
    #   an attr => direction mapping of sort orders
    #
    # @option [Fixnum] limit
    #   a limit to apply, defaults to 20 inside Sphinx itself
    #
    # @option [Fixnum] offset
    #   an offset to apply, defaults to 0
    #
    # @option [Array] conditions
    #   an array of a SQL WHERE conditions and the values to be escaped  
    #
    # @option [Hash] options
    #   a hash of options to apply to the query
    #
    # @option [Object] everything_else
    #   all additional options are taken to be attribute filters
    #
    # @return [Hash]
    #   a Hash containing meta data, with the records in :records, and if any
    #   facets were included, the facets inside the :facets Hash
    def search(*args)
      expand_facet_tree(multi_search(deep_merge_facets(args)))
    end

    # Perform a faceted search on the index, using a base query and one or more facets.
    #
    # This method is deprecated and will be removed in version 1.0. Use #search instead.
    #
    # @deprecated
    #
    # @see #search
    def faceted_search(*args)
      search(*args)
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

      # stmts       = []
      # bind_values = []

      rs = []

      queries.each do |key, args|
        str, *values = @builder.select(*extract_query_data(args))
        # stmts.push(str, "SHOW META")
        # bind_values.push(*values)
        rs.push @conn.query("#{str};", *values)
        rs.push @conn.query("SHOW META;")
      end

      # rs = @conn.multi_query(stmts.join(";\n"), *bind_values)

      Hash[].tap do |result|
        queries.keys.each do |key|
          records, meta = rs.shift, rs.shift
          result[key] = meta_to_hash(meta).tap do |r|
            r[:records] = records.map { |hash|
              hash.inject({}) { |o, (k, v)| o.merge!(k.to_sym => v) }
            }
          end
        end
      end
    end

    private

    def meta_to_hash(meta)
      Hash[].tap do |hash|
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

        if hash.key?(:docs) && hash.key?(:hits) && hash.key?(:keywords)
          hash[:docs] = Hash[(hash[:keywords]).zip(hash[:docs])]
          hash[:hits] = Hash[(hash[:keywords]).zip(hash[:hits])]
        end
      end
    end

    def extract_query_data(args, default_query = "")
      args = [args] unless Array === args

      unless (1..2) === args.size
        raise ArgumentError, "Wrong number of query arguments (#{args.size} for 1..2)"
      end

      case args[0]
      when String then [args[0],       args.fetch(1, {}).dup]
      when Hash   then [default_query, args[0].dup          ]
      else raise ArgumentError, "Invalid query argument type #{args.first.class}"
      end
    end

    def expand_facet_tree(result)
      Hash[].tap do |tree|
        result.each do |k, v|
          t = tree

          k.each do |name|
            f = t[:facets] ||= {}
            t = f[name]    ||= {}
          end

          t.merge!(v)
        end
      end
    end

    def deep_merge_facets(base_args, list = {}, path = [])
      # FIXME: Try and make this shorter and more functional in style
      base_query, base_options = extract_query_data(base_args)

      facets = base_options.delete(:facets)

      list.merge!(path => [base_query, base_options])

      unless facets.nil?
        facets.each do |k, q|
          facet_query, facet_options = extract_query_data(q, base_query)

          deep_merge_facets(
            [
              facet_query.gsub("%{query}", base_query),
              base_options.merge(facet_options)
            ],
            list,
            path.dup << k
          )
        end
      end

      list
    end
  end
end
