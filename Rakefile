# frozen_string_literal: true

require_relative 'lib/standup_md'
require 'bundler/gem_tasks'
require 'rdoc/task'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ['lib']
  t.warning = true
  t.verbose = true
  t.test_files = FileList['test/**/*_test.rb']
end

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
end

task default: :test
