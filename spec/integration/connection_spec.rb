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
    it "returns an index" do
      conn[:posts_rt].should be_a_kind_of(Oedipus::Index)
    end
  end

  describe "#query" do
    it "accepts integer bind parameters" do
      conn.query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", 1, 7)
    end

    it "accepts float bind parameters" do
      conn.query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", 1.2, 7.2)
    end

    it "accepts decimal bind parameters" do
      require "bigdecimal"
      conn.query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", BigDecimal("1.2"), BigDecimal("7.2"))
    end

    xit "accepts string bind parameters" do
      conn.query("SELECT * FROM posts_rt WHERE state = ?", "something")
    end
  end

  describe "#multi_query" do
    it "accepts integer bind parameters" do
      conn.multi_query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", 1, 7)
    end

    it "accepts float bind parameters" do
      conn.multi_query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", 1.2, 7.2)
    end

    it "accepts decimal bind parameters" do
      require "bigdecimal"
      conn.multi_query("SELECT * FROM posts_rt WHERE views = ? AND user_id = ?", BigDecimal("1.2"), BigDecimal("7.2"))
    end

    xit "accepts string bind parameters" do
      conn.multi_query("SELECT * FROM posts_rt WHERE state = ?", "something")
    end
  end

  describe "#execute" do
    it "accepts integer bind parameters" do
      conn.execute("REPLACE INTO posts_rt (id, views) VALUES (?, ?)", 1, 7)
    end

    it "accepts float bind parameters" do
      conn.execute("REPLACE INTO posts_rt (id, views) VALUES (?, ?)", 1, 7.2)
    end

    it "accepts decimal bind parameters" do
      require "bigdecimal"
      conn.execute("REPLACE INTO posts_rt (id, views) VALUES (?, ?)", 1, BigDecimal("7.2"))
    end

    it "accepts string bind parameters" do
      conn.execute("REPLACE INTO posts_rt (id, title) VALUES (?, ?)", 1, "an example with `\"this (quoted) string\\'")
    end
  end
end
