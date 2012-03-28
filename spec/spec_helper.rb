# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "rspec"
require "bundler/setup"
require "oedipus"

Dir[File.expand_path("../support/**/*rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  include Oedipus::TestHarness

  config.before(:suite) do
    unless ENV.key?("SEARCHD")
      raise "You must specify a path to the Sphinx 'searchd' executable (>= 2.0.2)"
    end
  end

  config.before(:each) do
    set_data_dir File.expand_path("../data", __FILE__)
    set_searchd  ENV["SEARCHD"]

    prepare_data_dirs
    write_sphinx_conf
    start_searchd
  end

  config.after(:each) do
    stop_searchd
  end
end
