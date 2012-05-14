# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"
require "oedipus/rspec/test_harness"

describe Oedipus::Connection::Registry do
  include Oedipus::RSpec::TestHarness

  before(:all) do
    set_data_dir File.expand_path("../../../data", __FILE__)
    set_searchd  ENV["SEARCHD"]
    start_searchd
  end

  after(:all) { stop_searchd }

  before(:each) { empty_indexes }

  let(:registry) do
    Object.new.tap { |o| o.send(:extend, Oedipus::Connection::Registry) }
  end

  describe "#connect" do
    it "makes a new connection to a SphinxQL host" do
      registry.connect(searchd_host).should be_a_kind_of(Oedipus::Connection)
    end
  end

  describe "#connection" do
    context "without a name" do
      let(:conn) { registry.connect(searchd_host) }

      it "returns an existing connection" do
        conn.should equal registry.connection
      end
    end

    context "with a name" do
      let(:conn) { registry.connect(searchd_host, :bob) }

      it "returns the named connection" do
        conn.should equal registry.connection(:bob)
      end
    end

    context "with a bad name" do
      it "raises an ArgumentError" do
        expect { registry.connection(:wrong) }.to raise_error(ArgumentError)
      end
    end
  end
end
