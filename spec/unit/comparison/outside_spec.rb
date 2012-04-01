# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::Outside do
  context "with an inclusive range" do
    let(:comparison) { Oedipus::Comparison::Outside.new(42..100) }

    it "draws as NOT BETWEEN x AND y" do
      comparison.to_s.should == "NOT BETWEEN 42 AND 100"
    end

    it "inverses as BETWEEN x AND y" do
      comparison.inverse.to_s.should == "BETWEEN 42 AND 100"
    end
  end

  context "with an exclusive range" do
    let(:comparison) { Oedipus::Comparison::Outside.new(42...100) }

    it "draws as NOT BETWEEN x AND y-1" do
      comparison.to_s.should == "NOT BETWEEN 42 AND 99"
    end

    it "inverses as BETWEEN x AND y-1" do
      comparison.inverse.to_s.should == "BETWEEN 42 AND 99"
    end
  end
end
