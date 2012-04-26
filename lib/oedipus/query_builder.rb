# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Constructs SphinxQL queries from the internal Hash format.
  class QueryBuilder
    # Initialize a new QueryBuilder for +index_name+.
    #
    # @param [Symbol] index_name
    #   the name of the index being queried
    def initialize(index_name)
      @index_name = index_name
    end

    # Build a SphinxQL query for the fulltext search +query+ and filters in +filters+.
    #
    # @param [String] query
    #   the fulltext query to execute (may be empty)
    #
    # @param [Hash] filters
    #   additional attribute filters and other options
    #
    # @return [String]
    #   a SphinxQL query
    def select(query, filters)
      [
        from(filters),
        conditions(query, filters),
        order_by(filters),
        limits(filters)
      ].join(" ")
    end

    # Build a SphinxQL query to insert the record identified by +id+ with the given attributes.
    #
    # @param [Fixnum] id
    #   the unique ID of the document to insert
    #
    # @param [Hash] attributes
    #   a Hash of attributes
    #
    # @return [String]
    #   the SphinxQL to insert the record
    def insert(id, attributes)
      into("INSERT", id, attributes)
    end

    # Build a SphinxQL query to update the record identified by +id+ with the given attributes.
    #
    # @param [Fixnum] id
    #   the unique ID of the document to update
    #
    # @param [Hash] attributes
    #   a Hash of attributes
    #
    # @return [String]
    #   the SphinxQL to update the record
    def update(id, attributes)
      [
        "UPDATE #{@index_name} SET",
        update_attributes(attributes),
        "WHERE id = #{Connection.quote(id)}"
      ].join(" ")
    end

    # Build a SphinxQL query to replace the record identified by +id+ with the given attributes.
    #
    # @param [Fixnum] id
    #   the unique ID of the document to replace
    #
    # @param [Hash] attributes
    #   a Hash of attributes
    #
    # @return [String]
    #   the SphinxQL to replace the record
    def replace(id, attributes)
      into("REPLACE", id, attributes)
    end

    private

    private

    def fields(filters)
      filters.fetch(:attrs, [:*]).dup.tap do |fields|
        if fields.none? { |a| /\brelevance\n/ === a } && normalize_order(filters).key?(:relevance)
          fields << "WEIGHT() AS relevance"
        end
      end
    end

    def from(filters)
      [
        "SELECT",
        fields(filters).join(", "),
        "FROM",
        @index_name
      ].join(" ")
    end

    def into(type, id, attributes)
      [
        type,
        "INTO #{@index_name}",
        "(#{([:id] + attributes.keys).join(', ')})",
        "VALUES",
        "(#{([id] + attributes.values).map { |v| Connection.quote(v) }.join(', ')})"
      ].join(" ")
    end

    def conditions(query, filters)
      exprs = []
      exprs << "MATCH(#{Connection.quote(query)})" unless query.empty?
      exprs += attribute_conditions(filters)
      "WHERE " << exprs.join(" AND ") if exprs.any?
    end

    def attribute_conditions(filters)
      filters \
        .reject { |k, v| [:attrs, :limit, :offset, :order].include?(k.to_sym) } \
        .map    { |k, v| "#{k} #{Comparison.of(v)}" }
    end

    def update_attributes(attributes)
      attributes \
        .map    { |k, v| "#{k} = #{Connection.quote(v)}" } \
        .join(", ")
    end

    def order_by(filters)
      return unless (order = normalize_order(filters)).any?

      [
        "ORDER BY",
        order.map { |k, dir| "#{k} #{dir.to_s.upcase}" }.join(", ")
      ].join(" ")
    end

    def normalize_order(filters)
      Hash[Array(filters[:order]).map { |k, v| [k.to_sym, v || :asc] }]
    end

    def limits(filters)
      "LIMIT #{filters[:offset].to_i}, #{filters[:limit].to_i}" if filters.key?(:limit)
    end
  end
end
