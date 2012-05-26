# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "spec_helper"
require "oedipus/rspec/test_rig"

describe Oedipus::Connection::Registry do
  include_context "oedipus test rig"
  include_context "oedipus posts_rt"

  let(:registry) do
    Object.new.tap { |o| o.send(:extend, Oedipus::Connection::Registry) }
  end

  describe "#connect" do
    it "makes a new connection to a SphinxQL host" do
      registry.connect(connection.options).should be_a_kind_of(Oedipus::Connection)
    end
  end

  describe "#connection" do
    context "without a name" do
      let(:conn) { registry.connect(connection.options) }

      it "returns an existing connection" do
        conn.should equal registry.connection
      end
    end

    context "with a name" do
      let(:conn) { registry.connect(connection.options, :bob) }

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
