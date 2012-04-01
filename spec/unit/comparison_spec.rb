# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison do
  subject { Oedipus::Comparison }

  describe "#of" do
    context "with a comparison" do
      it "returns the comparison" do
        subject.of(
          Oedipus::Comparison::Equal.new(7)
        ).should == Oedipus::Comparison::Equal.new(7)
      end
    end

    context "with a Fixnum" do
      it "returns an Equal comparison" do
        subject.of(7).should == Oedipus::Comparison::Equal.new(7)
      end
    end

    context "with a Float" do
      it "returns an Equal comparison" do
        subject.of(7.2).should == Oedipus::Comparison::Equal.new(7.2)
      end
    end

    context "with a BigDecimal" do
      it "returns an Equal comparison" do
        subject.of(BigDecimal("7.2")).should == Oedipus::Comparison::Equal.new(7.2)
      end
    end

    context "with a Rational" do
      it "returns an Equal comparison" do
        subject.of(Rational("1/3")).should == Oedipus::Comparison::Equal.new(Rational("1/3").to_f)
      end
    end

    context "with a String" do
      it "returns an Equal comparison" do
        subject.of("test").should == Oedipus::Comparison::Equal.new("test")
      end
    end

    context "with a Symbol" do
      it "returns an Equal comparison" do
        subject.of(:test).should == Oedipus::Comparison::Equal.new(:test)
      end
    end

    context "with a range" do
      context "starting at -Infinity" do
        context "inclusive" do
          it "returns a LTE comparison" do
            subject.of(-Float::INFINITY..10).should == Oedipus::Comparison::LTE.new(10)
          end
        end

        context "exclusive" do
          it "returns a LT comparison" do
            subject.of(-Float::INFINITY...10).should == Oedipus::Comparison::LT.new(10)
          end
        end
      end

      context "ending at -Infinity" do
        context "inclusive" do
          it "returns a GTE comparison" do
            subject.of(10..Float::INFINITY).should == Oedipus::Comparison::GTE.new(10)
          end
        end

        context "exclusive" do
          it "returns a GT comparison" do
            subject.of(10...Float::INFINITY).should == Oedipus::Comparison::GT.new(10)
          end
        end
      end

      context "of real numbers" do
        it "returns a BETWEEN comparison" do
          subject.of(10..20).should == Oedipus::Comparison::Between.new(10..20)
        end
      end
    end

    context "with an array" do
      it "returns an IN comparison" do
        subject.of([1, 2, 3]).should == Oedipus::Comparison::In.new([1, 2, 3])
      end
    end

    context "with an Enumerable type" do
      it "returns an IN comparison" do
        require 'set'
        subject.of(Set[1, 2, 3]).should == Oedipus::Comparison::In.new([1, 2, 3])
      end
    end
  end
end
