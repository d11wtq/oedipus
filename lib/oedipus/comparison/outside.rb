# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Outside comparison of range.
  class Comparison::Outside < Comparison
    def to_sql
      ["NOT BETWEEN ? AND ?", v.first, v.exclude_end? ? v.end - 1 : v.end]
    end

    def inverse
      Comparison::Between.new(v)
    end
  end
end
