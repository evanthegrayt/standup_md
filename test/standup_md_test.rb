# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/standup_md'

class TestStandupMD < TestHelper
  def setup
    StandupMD.instance_variable_set('@config_file_loaded', false)
  end

  def test_config
    assert_instance_of(StandupMD::Config, StandupMD.config)
  end

  def test_reset_config
    assert_instance_of(StandupMD::Config, StandupMD.reset_config)
  end

  def test_file
    assert_instance_of(StandupMD::Config::File, StandupMD.config.file)
  end

  def test_cli
    assert_instance_of(StandupMD::Config::Cli, StandupMD.config.cli)
  end

  def test_entry
    assert_instance_of(StandupMD::Config::Entry, StandupMD.config.entry)
  end

  def test_entry_list
    assert_instance_of(StandupMD::Config::EntryList, StandupMD.config.entry_list)
  end

  def test_version
    assert_match(/\d+\.\d+.\d+/, StandupMD::VERSION)
  end

  def test_configure
    assert_nothing_raised do
      StandupMD.configure do |s|
        s.file.directory    = workdir
        s.cli.editor        = 'mate'
        s.entry.impediments = ['Nothing']
      end
    end
    assert_equal(workdir, StandupMD.config.file.directory)
    assert_equal('mate', StandupMD.config.cli.editor)
    assert_equal(['Nothing'], StandupMD.config.entry.impediments)
  end

  def test_load_config_file
    create_config_file(test_config_file_name)
    refute(StandupMD.config_file_loaded?)
    assert_nothing_raised { StandupMD.load_config_file(test_config_file_name) }
    assert(StandupMD.config_file_loaded?)
    assert_equal(['NONE'], StandupMD.config.entry.impediments)
    assert_equal('Current', StandupMD.config.file.current_header)
    assert_equal('mate', StandupMD.config.cli.editor)
  end
end
