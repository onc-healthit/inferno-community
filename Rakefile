# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

task :default do
  ENV['RACK_ENV'] = 'test'
  Rake::Task['test'].invoke
end

Dir['lib/inferno/tasks/*.rake'].sort.each do |ext|
  load ext
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.test_files = Dir.glob('lib/inferno/modules/*/test/*_test.rb')
  t.verbose = true
  t.warning = false
end

desc 'Run rubocop'
task :rubocop do
  RuboCop::RakeTask.new
end

task default: %i[test]
