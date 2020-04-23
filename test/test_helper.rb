require 'erb'
require 'date'
require 'yaml'
require 'test/unit'
require 'fileutils'

##
# Module to include in tests that provides helper functions.
module TestHelper

  ##
  # Reads the fixtures in as a hash.
  #
  # @return [Hash]
  def fixtures
    @test_helper_fixtures ||= YAML.load(ERB.new(File.read(
      File.join(__dir__, 'fixtures.yml.erb')
    )).result(binding))
  end

  ##
  # Creates +StandupUP+ instance. Directory must be passed, usually a
  # subdirectory of +test+, so we don't overwrite the user's standup file.
  #
  # @param [String] directory
  # @param [Hash] args Optional hash of attributes to set
  #
  # @return [StandupMD]
  def standup(directory, args = {})
    args['directory'] = directory
    StandupMD.load(args)
  end

  ##
  # Creates the standup file with entries.
  #
  # @param [String] file The name of the file to create
  #
  # @param [String] fixture Fixture to add to the file
  #
  # @return [Hash]
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
