require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

Rake::ExtensionTask.new('oedipus') do |ext|
  ext.lib_dir = File.join('lib', 'oedipus')
end

desc "Run the full RSpec suite (requires SEARCHD environment variable)"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern     = 'spec/'
end

desc "Run the RSpec unit tests alone"
RSpec::Core::RakeTask.new('spec:unit') do |t|
  t.pattern = 'spec/unit/'
end

desc "Run the integration tests (requires SEARCHD environment variable)"
RSpec::Core::RakeTask.new('spec:integration') do |t|
  t.pattern = 'spec/integration/'
end

Rake::Task['spec'].prerequisites << :compile
Rake::Task['spec:unit'].prerequisites << :compile
Rake::Task['spec:integration'].prerequisites << :compile
