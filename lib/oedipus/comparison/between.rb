# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Between comparison of range.
  class Comparison::Between < Comparison
    def to_sql
      ["BETWEEN ? AND ?", v.first, v.exclude_end? ? v.end - 1 : v.end]
    end

    def inverse
      Comparison::Outside.new(v)
    end
  end
end
