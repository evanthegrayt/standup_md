require 'erb'
require 'date'
require 'yaml'
require 'test/unit'
require 'fileutils'

module TestHelper
  def fixtures
    @test_helper_fixtures ||= YAML.load(ERB.new(File.read(
      File.join(__dir__, 'fixtures.yml.erb')
    )).result(binding))
  end

  def standup(directory, args = {})
    StandupMD.new do |s|
      s.directory = directory
      args.each { |k, v| s.sendN("#{k}=", v) }
    end
  end

  def create_standup_file(file, fixture = 'previous_entry')
    dir = File.dirname(file)
    FileUtils.mkdir(dir) unless File.directory?(dir)
    File.open(file, 'w') do |f|
      f.puts fixtures[fixture]
      f.puts
      f.puts fixtures['current_entry']
    end
  end
end
