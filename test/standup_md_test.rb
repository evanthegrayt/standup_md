# frozen_string_literal: true

require_relative "test_helper"

class TestStandupMD < TestHelper
  def setup
    StandupMD.reset_config
    StandupMD.instance_variable_set(:@config_file_loaded, false)
  end

  def test_config
    assert_instance_of(StandupMD::Config, StandupMD.config)
  end

  def test_config_copy
    StandupMD.config.cli.verbose = true
    StandupMD.config.file.sub_header_order = %w[current previous]
    StandupMD.config.entry.current = ["Global current"]
    StandupMD.config.post.default_adapter = :test
    StandupMD.config.post.register_adapter(:test, StandupMD::Post::Adapter)
    StandupMD.config.post.configure_adapter(:test, channel: "configured")

    copy = StandupMD.config.copy
    copy.cli.verbose = false
    copy.file.sub_header_order << "notes"
    copy.entry.current << "Runtime current"
    copy.post.default_adapter = :runtime
    copy.post.configure_adapter(:test, channel: "runtime")

    refute(copy.cli.verbose)
    assert_equal(%w[current previous notes], copy.file.sub_header_order)
    assert_equal(["Global current", "Runtime current"], copy.entry.current)
    assert_equal(:runtime, copy.post.default_adapter)
    assert_equal({channel: "runtime"}, copy.post.options_for(:test))

    assert(StandupMD.config.cli.verbose)
    assert_equal(%w[current previous], StandupMD.config.file.sub_header_order)
    assert_equal(["Global current"], StandupMD.config.entry.current)
    assert_equal(:test, StandupMD.config.post.default_adapter)
    assert_equal({channel: "configured"}, StandupMD.config.post.options_for(:test))
  end

  def test_reset_config
    assert_instance_of(StandupMD::Config, StandupMD.reset_config)
  end

  def test_class_config_readers_use_current_config
    original_file_config = StandupMD::File.config
    original_cli_config = StandupMD::Cli.config
    original_entry_config = StandupMD::Entry.config
    original_entry_list_config = StandupMD::EntryList.config

    StandupMD.reset_config

    refute_same(original_file_config, StandupMD::File.config)
    refute_same(original_cli_config, StandupMD::Cli.config)
    refute_same(original_entry_config, StandupMD::Entry.config)
    refute_same(original_entry_list_config, StandupMD::EntryList.config)
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
        s.file.directory = workdir
        s.cli.editor = "mate"
        s.entry.impediments = ["Nothing"]
      end
    end
    assert_equal(workdir, StandupMD.config.file.directory)
    assert_equal("mate", StandupMD.config.cli.editor)
    assert_equal(["Nothing"], StandupMD.config.entry.impediments)
  end

  def test_load_config_file
    create_config_file(test_config_file_name)
    refute(StandupMD.config_file_loaded?)
    assert_nothing_raised { StandupMD.load_config_file(test_config_file_name) }
    assert(StandupMD.config_file_loaded?)
    assert_equal(["NONE"], StandupMD.config.entry.impediments)
    assert_equal("Current", StandupMD.config.file.current_header)
    assert_equal("mate", StandupMD.config.cli.editor)
  end
end
