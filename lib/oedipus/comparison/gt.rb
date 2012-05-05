# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Greater than comparison of +v+.
  class Comparison::GT < Comparison
    def to_sql
      ["> ?", v]
    end

    def inverse
      Comparison::LTE.new(v)
    end
  end
end
