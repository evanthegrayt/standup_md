require_relative 'lib/standup_md'

task :default => :test

desc "Build the gem"
task :build do
  system('gem build standup_md.gemspec')
end

desc "Build and install the gem"
task install: [:build] do
  system("gem install standup_md-#{StandupMD::VERSION}.gem")
end

desc "Uninstall the gem"
task :uninstall do
  system('gem uninstall standup')
end

desc "Run test suite"
task :test do
  Dir.glob(File.join(__dir__, 'test', '**', '*_test.rb')).each { |f| ruby f }
end

desc "Generate documentation"
task :doc do
  system('rdoc')
end
