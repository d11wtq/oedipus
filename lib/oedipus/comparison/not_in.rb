# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # NOT IN comparison of +v+.
  class Comparison::NotIn < Comparison
    def to_s
      "NOT IN (#{v.map { |o| Connection.quote(o)}.join(', ')})"
    end

    def inverse
      Comparison::In.new(v)
    end
  end
end
