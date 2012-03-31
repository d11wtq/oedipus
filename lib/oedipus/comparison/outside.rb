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
    def to_s
      [
        "NOT BETWEEN",
        Connection.quote(v.first),
        "AND",
        Connection.quote(v.exclude_end? ? v.end - 1 : v.end)
      ].join(" ")
    end

    def inverse
      Comparison::Between.new(v)
    end
  end
end
