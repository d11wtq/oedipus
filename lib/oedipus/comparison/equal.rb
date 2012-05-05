# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Equality comparison of value.
  class Comparison::Equal < Comparison
    def to_sql
      ["= ?", v]
    end

    def inverse
      Comparison::NotEqual.new(v)
    end
  end
end
