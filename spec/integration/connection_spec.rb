# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"
require "oedipus/rspec/test_harness"

describe Oedipus::Connection do
  include Oedipus::RSpec::TestHarness

  before(:all) do
    set_data_dir File.expand_path("../../data", __FILE__)
    set_searchd  ENV["SEARCHD"]
    start_searchd
  end

  after(:all) { stop_searchd }

  before(:each) { empty_indexes }

  let(:conn) { Oedipus::Connection.new(searchd_host) }

  describe "#initialize" do
    context "with a hosname:port string" do
      context "on successful connection" do
        it "returns the connection" do
          Oedipus::Connection.new(searchd_host.values.join(":")).should be_a_kind_of(Oedipus::Connection)
        end
      end

      context "on failed connection" do
        it "raises an error" do
          expect {
            Oedipus::Connection.new("127.0.0.1:45346138")
          }.to raise_error(Oedipus::ConnectionError)
        end
      end
    end

    context "with an options Hash" do
      context "on successful connection" do
        it "returns the connection" do
          Oedipus::Connection.new(searchd_host).should be_a_kind_of(Oedipus::Connection)
        end
      end

      context "on failed connection" do
        it "raises an error" do
          expect {
            Oedipus::Connection.new(:host => "127.0.0.1", :port => 45346138)
          }.to raise_error(Oedipus::ConnectionError)
        end
      end
    end
  end

  describe "#[]" do
    let(:conn) { Oedipus::Connection.new(searchd_host) }

    it "returns an index" do
      conn[:posts_rt].should be_a_kind_of(Oedipus::Index)
    end
  end
end
