# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "bundler/gem_tasks"
require "rdoc/task"
require "rake/testtask"
require "semverve/task"
require "standup_md"

STANDARD_FILES = ["lib", "test"].freeze

Semverve::Task.new do |t|
  t.bundle_lock = true
end

Rake::TestTask.new do |t|
  t.libs = ["lib"]
  t.warning = true
  t.verbose = true
  t.test_files = FileList["test/**/*_test.rb"]
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = "docs"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
end

task default: :test

desc "Lint with the Standard Ruby style guide"
task :standard do
  require "standard"

  exit_code = Standard::Cli.new(STANDARD_FILES).run
  fail unless exit_code.zero?
end

desc "Lint and automatically make safe fixes with the Standard Ruby style guide"
task :"standard:fix" do
  require "standard"

  exit_code = Standard::Cli.new(STANDARD_FILES + ["--fix"]).run
  fail unless exit_code.zero?
end
