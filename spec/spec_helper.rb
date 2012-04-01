# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "bundler/setup"

require "rspec"
require "oedipus"

Dir[File.expand_path("../support/**/*rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
end
