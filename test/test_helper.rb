# frozen_string_literal: true

require 'simplecov'
require 'erb'
require 'date'
require 'yaml'
require 'test/unit'
require 'fileutils'
SimpleCov.start { add_filter %r{^/test/} }

##
# Module to include in tests that provides helper functions.
class TestHelper < Test::Unit::TestCase

  ##
  # The default setup method for all tests that inherit from this class.
  def setup
    FileUtils.mkdir(workdir)
  end

  ##
  # The default teardown method for all tests that inherit from this class.
  def teardown
    FileUtils.rm_r(workdir) if File.directory?(workdir)
  end

  ##
  # The name of the file used to test standup files.
  def test_file_name
    @test_file_name ||= File.join(workdir, Date.today.strftime('%Y_%m.md'))
  end

  ##
  # The name of the test config file.
  def test_config_file_name
    @test_config_file_name ||= File.join(workdir, 'standuprc')
  end

  ##
  # The name of the output file that will be used when redirecting stdout.
  def test_output_file
    @test_output_file ||= File.join(workdir, 'output.txt')
  end

  ##
  # The directory used for testing.
  def workdir
    @workdir ||= File.join(__dir__, 'files')
  end

  ##
  # Reads the fixtures in as a hash.
  def fixtures
    @test_helper_fixtures ||= YAML.load(ERB.new(File.read(
      File.join(__dir__, 'fixtures.yml.erb')
    )).result(binding))
  end

  ##
  # Creates +StandupUP+ instance. Directory must be passed, usually a
  # subdirectory of +test+, so we don't overwrite the user's standup file.
  def standup(directory, args = {})
    args['directory'] = directory
    StandupMD.load do |s|
      args.each { |k, v| s.public_send("#{k}=", v) }
    end
  end

  ##
  # Creates the standup file with entries.
  def create_standup_file(file, fixture = 'previous_entry')
    dir = File.dirname(file)
    FileUtils.mkdir(dir) unless File.directory?(dir)
    File.open(file, 'w') do |f|
      f.puts fixtures['current_entry']
      f.puts
      f.puts fixtures[fixture]
    end
  end

  ##
  # Creates instance of +Cli+.
  def cli(options = [], load_config = false)
    StandupMD::Cli.new(options, load_config)
  end

  ##
  # Creates a config file.
  def create_config_file(file)
    FileUtils.mkdir(workdir) unless File.directory?(workdir)
    File.open(file, 'w+') do |f|
      f.puts "StandupMD.config.entry.impediments = ['NONE']"
      f.puts "StandupMD.config.file.current_header = 'Current'"
      f.puts "StandupMD.config.cli.editor = 'mate'"
    end
  end

  ##
  # Changes stdout to write to a file so we can test output if desired.
  # Don't forget to `ensure reset_io_stream`!
  def enable_stdout_redirection
    $stdout = File.open(test_output_file, 'w')
  end

  ##
  # Resets stdout back to default.
  def disable_stdout_redireaction
    return if $stdout == STDOUT
    $stdout.close
    $stdout = STDOUT
  end
end
