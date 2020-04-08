INSTALL_PATH = File.expand_path(File.join(File.dirname(__FILE__)), '..').freeze
LINK_TO = File.join(File::SEPARATOR, 'usr', 'local', 'bin', 'standup').freeze
LINK_FROM = File.join(INSTALL_PATH, 'bin', 'standup').freeze

task :default => :install

desc "Install to `/usr/local/bin`"
task :install do
  File.symlink(LINK_FROM, LINK_TO) unless File.symlink?(LINK_TO)
end

desc "Uninstall"
task :uninstall do
  File.delete(LINK_TO) if File.symlink?(LINK_TO)
end

desc "Tag and pull from master"
task :update do
  sh("git tag #{Time.now.strftime('%Y-%m-%d-%H%M')}")
  sh("git pull origin master")
end

desc "Checking out last deployment tag"
task :rollback do
  tags = `git tag`.strip.split("\n")
  sh("git checkout #{tags.last}")
end

desc "Run rspec tests"
task :test do
  Dir.glob(File.join(__dir__, 'test', '**', '*_test.rb')).each do |file|
    ruby file
  end
end
