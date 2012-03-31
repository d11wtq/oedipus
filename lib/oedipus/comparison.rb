# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Represents a comparison operator and value.
  class Comparison
    class << self
      # Return a suitable comparison object for +v+.
      #
      # The conversions are:
      #
      #   - leave Comparison objects unchanged
      #   - convert real ranges to Between comparisons
      #   - convert Infinity-bounded exclusive ranges to GT/LT comparisons
      #   - convert Infinity-bounded inclusive ranges to GTE/LTE comparisons.
      #   - convert everything else to an Equal comparison
      #
      # @param [Object] v
      #   a ruby object to be compared
      #
      # @param [Comparison]
      #   a comparison suitable for comparing the input
      def of(v)
        case v
        when Comparison
          v
        when Range
          if v.end == (1/0.0)
            v.exclude_end? ? GT.new(v.first) : GTE.new(v.first)
          elsif v.first == -(1/0.0)
            v.exclude_end? ? LT.new(v.end) : LTE.new(v.end)
          else
            Between.new(v)
          end
        else
          Equal.new(v)
        end
      end
    end

    attr_reader :v

    # Initialize a new Comparison for +v+.
    #
    # @param [Object] v
    #   any ruby object to compare
    def initialize(v)
      @v = v
    end

    # Return the exact inverse of this comparison.
    #
    # @return [Comparison]
    #   the inverse of the current comparison
    def inverse
      raise NotImplementedError, "Comparison#inverse must be defined by subclasses"
    end

    # Represent the comparison as a string.
    #
    # @return [String]
    #   an expression to compare a LHS against v
    def to_s
      raise NotImplementedError, "Comparison#to_s must be defined by subclasses"
    end
  end
end
