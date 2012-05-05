# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Comparison::Equal do
  let(:comparison) { Oedipus::Comparison::Equal.new('test') }

  it "draws as = v" do
    comparison.to_sql.should == ["= ?", "test"]
  end

  it "inverses as != v" do
    comparison.inverse.to_sql.should == ["!= ?", "test"]
  end
end
