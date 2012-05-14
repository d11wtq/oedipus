# encoding: utf-8

##
# Oedipus Sphinx 2 Search.
# Copyright © 2012 Chris Corbyn.
#
# See LICENSE file for details.
##

require "oedipus/version"

require "oedipus/oedipus"

require "oedipus/comparison"
require "oedipus/comparison/equal"
require "oedipus/comparison/not_equal"
require "oedipus/comparison/between"
require "oedipus/comparison/outside"
require "oedipus/comparison/in"
require "oedipus/comparison/not_in"
require "oedipus/comparison/gte"
require "oedipus/comparison/gt"
require "oedipus/comparison/lte"
require "oedipus/comparison/lt"
require "oedipus/comparison/not"
require "oedipus/comparison/shortcuts"

require "oedipus/query_builder"

require "oedipus/connection_error"
require "oedipus/connection"
require "oedipus/connection/pool"
require "oedipus/connection/registry"

require "oedipus/index"

module Oedipus
  extend Comparison::Shortcuts
  extend Connection::Registry
end
