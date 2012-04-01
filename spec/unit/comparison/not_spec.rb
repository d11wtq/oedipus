# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::In do
  context "with a non-comparison" do
    let(:comparison) { Oedipus::Comparison::Not.new(0..10) }

    it "converts to a comparison" do
      comparison.v.should be_a_kind_of(Oedipus::Comparison)
    end

    it "returns the comparison as its inverse" do
      comparison.inverse.should == comparison.v
    end
  end

  context "with a comparison" do
    let(:original)   { Oedipus::Comparison::GTE.new(7) }
    let(:comparison) { Oedipus::Comparison::Not.new(original) }

    it "draws as the inverse of the comparison" do
      comparison.to_s.should == original.inverse.to_s
    end

    it "inverses as the original" do
      comparison.inverse.to_s == original.to_s
    end
  end
end
