require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

Rake::ExtensionTask.new('oedipus') do |ext|
  ext.lib_dir = File.join('lib', 'oedipus')
end

RSpec::Core::RakeTask.new('spec')

Rake::Task[:spec].prerequisites << :compile
