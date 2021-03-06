# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  class Comparison
    # Provides short methods for casting values to Comparisons.
    module Shortcuts
      extend self

      # Return the Comparison for equality of +v+.
      #
      # @param [Object] v
      #   any ruby object to compare in a query
      #
      # @return [Comparison::Equal]
      #   an equality comparison of v
      def eq(v)
        Equal.new(v)
      end

      # Return the Comparison for inequality of +v+.
      #
      # @param [Object] v
      #   any ruby object to compare in a query
      #
      # @return [Comparison::Equal]
      #   an inequality comparison of v
      def neq(v)
        NotEqual.new(v)
      end

      # Return the Comparison for negation of +v+.
      #
      # @param [Object] v
      #   any ruby object to compare in a query
      #
      # @return [Comparison::Not]
      #   an negated comparison of v
      def not(v)
        Not.new(v)
      end

      # Return the Comparison for the range a..b.
      #
      # @param [Object] v
      #   either a Range, or a number
      #
      # @param [Fixnum] b
      #   if the first argument was a number, the other bound
      #
      # @return [Comparison::Between]
      #   an between comparison of a..b
      def between(a, b = nil)
        Between.new(a.kind_of?(Range) ? a : a..b)
      end

      # Return the Comparison to exclude the range a..b.
      #
      # @param [Object] v
      #   either a Range, or a number
      #
      # @param [Fixnum] b
      #   if the first argument was a number, the other bound
      #
      # @return [Comparison::Outside]
      #   an outside comparison of a..b
      def outside(a, b = nil)
        Outside.new(a.kind_of?(Range) ? a : a..b)
      end

      # Return the Comparison for any value in the set +v+.
      #
      # @param [Object] v
      #   any ruby object to compare
      #
      # @return [Comparison::In]
      #   the IN comparison for the values in v
      def in(*v)
        In.new(v.map { |el| el.respond_to?(:to_a) ? el.to_a : el }.flatten)
      end

      # Return the Comparison for any value NOT in the set +v+.
      #
      # @param [Object] v
      #   any ruby object to compare
      #
      # @return [Comparison::NotIn]
      #   the NOT IN comparison for the values in v
      def not_in(*v)
        NotIn.new(v.map { |el| el.respond_to?(:to_a) ? el.to_a : el }.flatten)
      end

      # Return the Comparison for >= +v+.
      #
      # @param [Object] v
      #   a number to compare
      #
      # @return [Comparison::GTE]
      #   a greater than or equal comparison for v
      def gte(v)
        GTE.new(v)
      end

      # Return the Comparison for > +v+.
      #
      # @param [Object] v
      #   a number to compare
      #
      # @return [Comparison::GT]
      #   a greater than comparison for v
      def gt(v)
        GT.new(v)
      end

      # Return the Comparison for <= +v+.
      #
      # @param [Object] v
      #   a number to compare
      #
      # @return [Comparison::LTE]
      #   a less than or equal comparison for v
      def lte(v)
        LTE.new(v)
      end

      # Return the Comparison for < +v+.
      #
      # @param [Object] v
      #   a number to compare
      #
      # @return [Comparison::LT]
      #   a less than comparison for v
      def lt(v)
        LT.new(v)
      end
    end
  end
end
