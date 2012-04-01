# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::LT do
  let(:comparison) { Oedipus::Comparison::LT.new(42) }

  it "draws as < v" do
    comparison.to_s.should == "< 42"
  end

  it "inverses as >= v" do
    comparison.inverse.to_s.should == ">= 42"
  end
end
