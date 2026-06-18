# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "standup_md"
require "bundler/gem_tasks"
require "rdoc/task"
require "rake/testtask"

STANDARD_FILES = ["lib", "test"].freeze

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

task default: :test

namespace :version do
  desc "Print the current version from the version.rb file"
  task :current do
    puts StandupMD::VERSION
  end

  namespace :increment do
    desc "Increment the version's PATCH level"
    task :patch do
      File.join(__dir__, "lib", "standup_md", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file).sub(/(PATCH\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
    desc "Increment the version's MINOR level"
    task :minor do
      File.join(__dir__, "lib", "standup_md", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file)
            .sub(/(PATCH\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MINOR\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
    desc "Increment the version's MAJOR level"
    task :major do
      File.join(__dir__, "lib", "standup_md", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file)
            .sub(/(PATCH\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MINOR\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MAJOR\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
  end
end
