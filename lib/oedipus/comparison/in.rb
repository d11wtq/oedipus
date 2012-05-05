# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # IN comparison of +v+.
  class Comparison::In < Comparison
    def to_sql
      ["IN (#{v.map{'?'}.join(', ')})", *v]
    end

    def inverse
      Comparison::NotIn.new(v)
    end
  end
end
