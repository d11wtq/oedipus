# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::Index do
  let(:conn)  { Oedipus::Connection.new(searchd_host) }
  let(:index) { Oedipus::Index.new(:posts_rt, conn) }

  describe "#insert" do
    context "with valid data" do
      it "returns the inserted attributes as a Hash" do
        index.insert(
          10,
          title:   "Badgers",
          body:    "They live in setts, do badgers.",
          views:   721,
          user_id: 7
        ).should == { id: 10, views: 721, user_id: 7, status: "" }
      end
    end

    context "with invalid data" do
      it "raises an error" do
        expect {
          index.insert(
            10,
            bad_field: "Invalid",
            body:      "They live in setts, do badgers.",
            views:     721,
            user_id:   7
          )
        }.to raise_error
      end
    end
  end

  describe "#search" do
    before(:each) do
      index.insert(1, title: "Badgers and foxes",   views: 150)
      index.insert(2, title: "Rabbits and hares",   views: 87)
      index.insert(3, title: "Badgers in the wild", views: 41)
      index.insert(4, title: "Badgers for all!",    views: 3003)
    end

    context "by fulltext matching" do
      it "indicates the number of records found" do
        index.search("badgers")[:total_found].should == 3
      end

      it "includes the matches records" do
        index.search("badgers")[:records].should == [
          { id: 1, views: 150,  user_id: 0, status: "" },
          { id: 3, views: 41,   user_id: 0, status: "" },
          { id: 4, views: 3003, user_id: 0, status: "" }
        ]
      end
    end

    context "with limits" do
      it "still indicates the number of records found" do
        index.search("badgers", limit: 2)[:total_found].should == 3
      end

      it "returns the limited subset of the results" do
        index.search("badgers", limit: 2)[:records].should == [
          { id: 1, views: 150,  user_id: 0, status: "" },
          { id: 3, views: 41,   user_id: 0, status: "" }
        ]
      end

      it "can use an offset" do
        index.search("badgers", limit: 1, offset: 1)[:records].should == [
          { id: 3, views: 41,   user_id: 0, status: "" }
        ]
      end
    end
  end
end
