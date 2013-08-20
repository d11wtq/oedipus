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
      where, *bind_values = conditions(query, filters)
      [
        [
          from(filters),
          where,
          order_by(filters),
          limits(filters),
          options(filters)
        ].join(" "),
        *bind_values
      ]
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
      set_attrs, *bind_values = update_attributes(attributes)
      [
        [
          "UPDATE #{@index_name} SET",
          set_attrs,
          "WHERE id = ?"
        ].join(" "),
        *bind_values.push(id)
      ]
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

    # Build a SphinxQL query to delete the record identified by +id+.
    #
    # @param [Fixnum] id
    #   the unique ID of the document to delete
    #
    # @return [String]
    #   the SphinxQL to delete the record
    def delete(id)
      ["DELETE FROM #{@index_name} WHERE id = ?", id]
    end

    private

    RESERVED = [:attrs, :limit, :offset, :order, :options]

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
      attributes.merge!(id: id)

      value_substitute_str = attributes.values.collect do |attribute|
        attribute.is_a?(Array) ? "(#{(['?'] * attribute.size).join(', ')})" : '?'
      end.join(', ')

      [
        [
          type,
          "INTO #{@index_name}",
          "(#{attributes.keys.join(', ')})",
          "VALUES",
          "(#{value_substitute_str})"
        ].join(" "),
        *attributes.values.flatten
      ]
    end

    def conditions(query, filters)
      sql = []
      sql << ["MATCH(?)", query] unless query.empty?
      sql.push(filters.delete(:conditions)) if filters.has_key?(:conditions)
      sql.push(*attribute_conditions(filters))

      exprs, bind_values = sql.inject([[], []]) do |(strs, values), v|
        [strs.push(v.shift), values.push(*v)]
      end

      ["WHERE " << exprs.join(" AND "), *bind_values] if exprs.any?
    end

    def attribute_conditions(filters)
      filters.reject{ |k, v| RESERVED.include?(k.to_sym) }.map do |k, v|
        Comparison.of(v).to_sql.tap { |c| c[0].insert(0, "#{k} ") }
      end
    end

    def update_attributes(attributes)
      [
        attributes.keys.map{ |k| "#{k} = ?" }.join(", "),
        *attributes.values
      ]
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

    def options(filters)
      if filters.key?(:options)
        option_strs = filters[:options].map do |k, v| 
          "#{k} = #{v}" 
        end

        "OPTION #{option_strs.join(', ')}"
      end
    end
  end
end
