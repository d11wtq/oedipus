# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::NotIn do
  let(:comparison) { Oedipus::Comparison::NotIn.new([1, 2, 3]) }

  it "draws as NOT IN (x, y, z)" do
    comparison.to_s.should == "NOT IN (1, 2, 3)"
  end

  it "inverses as IN (x, y, z)" do
    comparison.inverse.to_s.should == "IN (1, 2, 3)"
  end
end
