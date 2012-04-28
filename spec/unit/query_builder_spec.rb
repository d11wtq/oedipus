# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"

describe Oedipus::QueryBuilder do
  let(:builder) { Oedipus::QueryBuilder.new(:posts) }

  describe "#select" do
    context "with a fulltext search" do
      it "uses MATCH()" do
        builder.select("dogs AND cats", {}).should =~ /SELECT .* FROM posts WHERE MATCH\('dogs AND cats'\)/
      end
    end

    context "without conditions" do
      it "does not add a where clause" do
        builder.select("", {}).should_not =~ /WHERE/
      end
    end

    context "with equal attribute filters" do
      it "uses the '=' operator" do
        builder.select("dogs", author_id: 7).should =~ /SELECT .* FROM posts WHERE .* author_id = 7/
      end
    end

    context "with not equal attribute filters" do
      it "uses the '!=' operator" do
        builder.select("dogs", author_id: Oedipus.not(7)).should =~ /SELECT .* FROM posts WHERE .* author_id != 7/
      end
    end

    context "with inclusive range-filtered attribute filters" do
      it "uses the BETWEEN operator" do
        builder.select("cats", views: 10..20).should =~ /SELECT .* FROM posts WHERE .* views BETWEEN 10 AND 20/
      end
    end

    context "with exclusive range-filtered attribute filters" do
      it "uses the BETWEEN operator" do
        builder.select("cats", views: 10...20).should =~ /SELECT .* FROM posts WHERE .* views BETWEEN 10 AND 19/
      end
    end

    context "with a greater than or equal comparison" do
      it "uses the >= operator" do
        builder.select("cats", views: 50..(1/0.0)).should =~ /SELECT .* FROM posts WHERE .* views >= 50/
      end
    end

    context "with a greater than comparison" do
      it "uses the > operator" do
        builder.select("cats", views: 50...(1/0.0)).should =~ /SELECT .* FROM posts WHERE .* views > 50/
      end
    end

    context "with a less than or equal comparison" do
      it "uses the <= operator" do
        builder.select("cats", views: -(1/0.0)..50).should =~ /SELECT .* FROM posts WHERE .* views <= 50/
      end
    end

    context "with a less than comparison" do
      it "uses the < operator" do
        builder.select("cats", views: -(1/0.0)...50).should =~ /SELECT .* FROM posts WHERE .* views < 50/
      end
    end

    context "with a negated range comparison" do
      it "uses the NOT BETWEEN operator" do
        builder.select("cats", views: Oedipus.not(50..100)).should =~ /SELECT .* FROM posts WHERE .* views NOT BETWEEN 50 AND 100/
      end
    end

    context "with an attributed filtered by collection" do
      it "uses the IN operator" do
        builder.select("cats", author_id: [7, 11]).should =~ /SELECT .* FROM posts WHERE .* author_id IN \(7, 11\)/
      end
    end

    context "with an attributed filtered by negated collection" do
      it "uses the NOT IN operator" do
        builder.select("cats", author_id: Oedipus.not([7, 11])).should =~ /SELECT .* FROM posts WHERE .* author_id NOT IN \(7, 11\)/
      end
    end

    context "with explicit attributes" do
      it "puts the attributes in the select clause" do
        builder.select("cats", attrs: [:*, "FOO() AS f"]).should =~ /SELECT \*, FOO\(\) AS f FROM posts/
      end
    end

    context "with a limit" do
      it "applies a LIMIT with an offset of 0" do
        builder.select("dogs", limit: 50).should =~ /SELECT .* FROM posts WHERE .* LIMIT 0, 50/
      end

      it "is not considered an attribute" do
        builder.select("dogs", limit: 50).should_not =~ /limit = 50/
      end
    end

    context "with an offset" do
      it "applies a LIMIT with an offset" do
        builder.select("dogs", limit: 50, offset: 200).should =~ /SELECT .* FROM posts WHERE .* LIMIT 200, 50/
      end

      it "is not considered an attribute" do
        builder.select("dogs", limit: 50, offset: 200).should_not =~ /offset = 200/
      end
    end

    context "with an order clause" do
      it "applies an ORDER BY" do
        builder.select("cats", order: {views: :desc}).should =~ /SELECT .* FROM posts WHERE .* ORDER BY views DESC/
      end

      it "defaults to ASC" do
        builder.select("cats", order: :views).should =~ /SELECT .* FROM posts WHERE .* ORDER BY views ASC/
      end

      it "supports multiple orders" do
        builder.select("cats", order: {views: :asc, author_id: :desc}).should =~ /SELECT .* FROM posts WHERE .* ORDER BY views ASC, author_id DESC/
      end

      context "by relevance" do
        it "injects a weight() attribute" do
          builder.select("cats", order: {relevance: :desc}).should =~ /SELECT \*, WEIGHT\(\) AS relevance FROM posts WHERE .* ORDER BY relevance DESC/
        end
      end
    end
  end

  describe "#insert" do
    it "includes the ID and the attributes" do
      builder.insert(3, title: "example", views: 9).should == "INSERT INTO posts (id, title, views) VALUES (3, 'example', 9)"
    end
  end

  describe "#update" do
    it "includes the ID in the WHERE clause" do
      builder.update(3, title: "example", views: 9).should =~ /UPDATE posts SET .* WHERE id = 3/
    end

    it "includes the changed attributes" do
      builder.update(3, title: "example", views: 9).should =~ /UPDATE posts SET title = 'example', views = 9/
    end
  end

  describe "#replace" do
    it "includes the ID and the attributes" do
      builder.replace(3, title: "example", views: 9).should == "REPLACE INTO posts (id, title, views) VALUES (3, 'example', 9)"
    end
  end

  describe "#delete" do
    it "includes the ID" do
      builder.delete(3).should == "DELETE FROM posts WHERE id = 3"
    end
  end
end
