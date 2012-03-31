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

  before(:each) { empty_indexes }

  describe "#insert" do
    context "with valid data" do
      it "returns the number of rows inserted" do
        index.insert(
          10,
          title:   "Badgers",
          body:    "They live in setts, do badgers.",
          views:   721,
          user_id: 7
        ).should == 1
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

  describe "#fetch" do
    before(:each) do
      index.insert(1, title: "Badgers and foxes",       views: 150)
      index.insert(2, title: "Rabbits and hares",       views: 73)
      index.insert(3, title: "Clowns and cannon girls", views: 1)
    end

    context "with a valid document ID" do
      it "returns the matched document" do
        index.fetch(2).should == { id: 2, views: 73,  user_id: 0, status: "" }
      end
    end

    context "with a bad document ID" do
      it "returns nil" do
        index.fetch(7).should be_nil
      end
    end
  end

  describe "#update" do
    before(:each) do
      index.insert(1, title: "Badgers and foxes", views: 150, user_id: 7)
    end

    context "with valid data" do
      it "returns the number of rows modified" do
        index.update(1, views: 721).should == 1
      end

      it "modifies the data" do
        index.update(1, views: 721)
        index.fetch(1).should == { id: 1, views: 721, user_id: 7, status: "" }
      end
    end

    context "with unmatched data" do
      it "returns 0" do
        index.update(
          3,
          views:   721
        ).should == 0
      end
    end

    context "with invalid data" do
      it "raises an error" do
        expect {
          index.insert(
            1,
            bad_field: "Invalid",
            views:     721
          )
        }.to raise_error
      end
    end
  end

  describe "#replace" do
    before(:each) do
      index.insert(
        1,
        title:   "Badgers",
        body:    "They live in setts, do badgers.",
        views:   721,
        user_id: 7
      )
    end

    context "with valid existing data" do
      it "returns the number of rows inserted" do
        index.replace(1, title: "Badgers and foxes", views: 150).should == 1
      end

      it "entirely replaces the record" do
        index.replace(1, title: "Badgers and foxes", views: 150)
        index.fetch(1).should == { id: 1, views: 150, user_id: 0, status: "" }
      end
    end

    context "with valid new data" do
      it "returns the number of rows inserted" do
        index.replace(2, title: "Beer and wine", views: 15).should == 1
      end

      it "entirely replaces the record" do
        index.replace(2, title: "Beer and wine", views: 15)
        index.fetch(2).should == { id: 2, views: 15, user_id: 0, status: "" }
      end
    end

    context "with invalid data" do
      it "raises an error" do
        expect {
          index.replace(1, bad_field: "Badgers and foxes", views: 150)
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

  describe "#multi_search" do
    before(:each) do
      index.insert(1, title: "Badgers and foxes",   views: 150)
      index.insert(2, title: "Rabbits and hares",   views: 87)
      index.insert(3, title: "Badgers in the wild", views: 41)
      index.insert(4, title: "Badgers for all!",    views: 3003)
    end

    it "indicates the number of results for each query" do
      results = index.multi_search(
        badgers: "badgers",
        rabbits: "rabbits"
      )
      results[:badgers][:total_found].should == 3
      results[:rabbits][:total_found].should == 1
    end

    it "returns the records for each search" do
      results = index.multi_search(
        badgers: "badgers",
        rabbits: "rabbits"
      )
      results[:badgers][:records].should == [
        { id: 1, views: 150,  user_id: 0, status: "" },
        { id: 3, views: 41,   user_id: 0, status: "" },
        { id: 4, views: 3003, user_id: 0, status: "" }
      ]
      results[:rabbits][:records].should == [
        { id: 2, views: 87, user_id: 0, status: "" }
      ]
    end
  end
end
