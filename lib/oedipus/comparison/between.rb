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
    def to_s
      [
        "BETWEEN",
        Connection.quote(v.first),
        "AND",
        Connection.quote(v.exclude_end? ? v.end - 1 : v.end)
      ].join(" ")
    end

    def inverse
      Comparison::Outside.new(v)
    end
  end
end
