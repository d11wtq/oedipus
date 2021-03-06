# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "oedipus/version"

Gem::Specification.new do |s|
  s.name        = "oedipus"
  s.version     = Oedipus::VERSION
  s.authors     = ["d11wtq"]
  s.email       = ["chris@w3style.co.uk"]
  s.homepage    = "https://github.com/d11wtq/oedipus"
  s.summary     = "Sphinx 2 Search Client for Ruby"
  s.description = <<-DESC.gsub(/^ {4}/m, "")
    == Sphinx 2 Comes to Ruby

    Oedipus brings full support for Sphinx 2 to Ruby:

      - real-time indexes (insert, replace, update, delete)
      - faceted search (variations on a base query)
      - multi-queries (multiple queries executed in a batch)
      - full attribute filtering support

    It works with 'stable' versions of Sphinx 2 (>= 2.0.2). All
    features are implemented entirely through the SphinxQL interface.
  DESC

  s.rubyforge_project = "oedipus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.extensions    = ["ext/oedipus/extconf.rb"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake-compiler"
end
