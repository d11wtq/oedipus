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
        ).should == { id: 10, user_id: 7, views: 721, user_id: 7, status: "" }
      end
    end

    context "with invalid data" do
      #
    end
  end

  describe "#search" do
    #p index.search("dog")
  end
end
