# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Negation comparison of value.
  class Comparison::Not < Comparison
    def initialize(v)
      super(Comparison.of(v))
    end

    def to_sql
      v.inverse.to_sql
    end

    def inverse
      v
    end
  end
end
