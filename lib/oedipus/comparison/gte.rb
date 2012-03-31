# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

module Oedipus
  # Greater than or equal comparison of +v+.
  class Comparison::GTE < Comparison
    def to_s
      ">= #{Connection.quote(v)}"
    end

    def inverse
      Comparison::LT.new(v)
    end
  end
end
