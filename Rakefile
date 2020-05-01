require_relative 'lib/standup_md'
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include("README.md", "**/*.rb")
end

task :default => :test

desc "Build the gem"
task :build do
  system('gem build standup_md.gemspec')
end

desc "Build and install the gem"
task install: [:dependencies, :build] do
  system("gem install standup_md-#{StandupMD::VERSION}.gem")
end

desc "Add dependencies"
task :dependencies do
  system("gem install bundler")
  system("bundle install")
end

desc "Uninstall the gem"
task :uninstall do
  system('gem uninstall standup_md')
end

desc "Run test suite"
task :test do
  Dir.glob(File.join(__dir__, 'test', '**', '*_test.rb')).each { |f| ruby f }
end

desc "Remove built gems from directory"
task :clean do
  Dir.glob('standup_md*.gem').each do |f|
    puts "Removing #{f}"
    FileUtils.rm(f)
  end
end
