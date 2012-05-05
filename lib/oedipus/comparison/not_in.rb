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
    def to_sql
      ["NOT IN (#{v.map{'?'}.join(', ')})", *v]
    end

    def inverse
      Comparison::In.new(v)
    end
  end
end
