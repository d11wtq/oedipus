# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Less than or equal comparison of +v+.
  class Comparison::LTE < Comparison
    def to_sql
      ["<= ?", v]
    end

    def inverse
      Comparison::GT.new(v)
    end
  end
end
