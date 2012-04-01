# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::Shortcuts do
  let(:s) { Object.new.tap { |o| o.extend subject } }

  describe "#eq" do
    it "returns the = comparison for v" do
      s.eq(7).should == Oedipus::Comparison::Equal.new(7)
    end
  end

  describe "#neq" do
    it "returns the != comparison for v" do
      s.neq(7).should == Oedipus::Comparison::NotEqual.new(7)
    end
  end


  describe "#not" do
    it "returns the NOT comparison for v" do
      s.not(7).should == Oedipus::Comparison::Not.new(7)
    end
  end

  describe "#gt" do
    it "returns the > comparison for v" do
      s.gt(7).should == Oedipus::Comparison::GT.new(7)
    end
  end

  describe "#lt" do
    it "returns the < comparison for v" do
      s.lt(7).should == Oedipus::Comparison::LT.new(7)
    end
  end

  describe "#gte" do
    it "returns the >= comparison for v" do
      s.gte(7).should == Oedipus::Comparison::GTE.new(7)
    end
  end

  describe "#lte" do
    it "returns the <= comparison for v" do
      s.lte(7).should == Oedipus::Comparison::LTE.new(7)
    end
  end

  describe "#between" do
    context "with a range" do
      it "returns the BETWEEN comparison for v" do
        s.between(7..11).should == Oedipus::Comparison::Between.new(7..11)
      end
    end

    context "with two bounds" do
      it "returns the BETWEEN comparison for x and y" do
        s.between(7, 11).should == Oedipus::Comparison::Between.new(7..11)
      end
    end
  end

  describe "#outside" do
    context "with a range" do
      it "returns the NOT BETWEEN comparison for v" do
        s.outside(7..11).should == Oedipus::Comparison::Outside.new(7..11)
      end
    end

    context "with two bounds" do
      it "returns the NOT BETWEEN comparison for x and y" do
        s.outside(7, 11).should == Oedipus::Comparison::Outside.new(7..11)
      end
    end
  end

  describe "#in" do
    context "with an array" do
      it "returns the IN comparison for v" do
        s.in([1, 2, 3]).should == Oedipus::Comparison::In.new([1, 2, 3])
      end
    end

    context "with a range" do
      it "returns the IN comparison for v" do
        s.in(1..3).should == Oedipus::Comparison::In.new([1, 2, 3])
      end
    end

    context "with a variable arguments" do
      it "returns the IN comparison for x, y, z" do
        s.in(1, 2, 3).should == Oedipus::Comparison::In.new([1, 2, 3])
      end
    end
  end

  describe "#not_in" do
    context "with an array" do
      it "returns the NOT IN comparison for v" do
        s.not_in([1, 2, 3]).should == Oedipus::Comparison::NotIn.new([1, 2, 3])
      end
    end

    context "with a range" do
      it "returns the NOT IN comparison for v" do
        s.not_in(1..3).should == Oedipus::Comparison::NotIn.new([1, 2, 3])
      end
    end

    context "with a variable arguments" do
      it "returns the NOT IN comparison for x, y, z" do
        s.not_in(1, 2, 3).should == Oedipus::Comparison::NotIn.new([1, 2, 3])
      end
    end
  end
end
