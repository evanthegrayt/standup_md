# frozen_string_literal: true

require_relative "../test_helper"

class TestFile < TestHelper
  def setup
    super
    StandupMD.config.file.reset
    StandupMD.config.file.directory = workdir
    @previous_month_test_file = Date.today.prev_month.strftime("%Y_%m.md")
    create_standup_file(test_file_name)
    @file = StandupMD::File.new(::File.basename(test_file_name))
  end

  def test_initialize
    assert_equal(
      test_file_name, StandupMD::File.new(::File.basename(test_file_name)).name
    )
    assert_equal(
      test_file_name,
      StandupMD::File.new(::File.basename(test_file_name)).name
    )
  end

  def test_new?
    file = StandupMD::File.new(
      Date.today.strftime(StandupMD.config.file.name_format)
    )
    refute(file.new?)

    file = StandupMD::File.new(
      Date.today.next_month.strftime(StandupMD.config.file.name_format)
    )
    assert(file.new?)
  end

  def test_find
    file = StandupMD::File.find(File.basename(test_file_name))
    assert_instance_of(StandupMD::File, file)
    assert_equal(test_file_name, file.name)
    StandupMD.config.file.create = false
    assert_raise { StandupMD::File.find("noexist") }
    StandupMD.config.file.create = true
    assert_nothing_raised { StandupMD::File.find("noexist") }
  end

  def test_find_does_not_depend_on_directory_entry_order
    earlier_file = Date.today.prev_month.strftime("%Y_%m.md")
    create_standup_file(::File.join(workdir, earlier_file), "previous_month_entry")
    directory = StandupMD.config.file.directory
    current_file = ::File.basename(test_file_name)
    active = true
    Dir.singleton_class.prepend(
      Module.new do
        define_method(:entries) do |requested_directory|
          if active && requested_directory == directory
            [
              current_file,
              earlier_file,
              ".",
              ".."
            ]
          else
            super(requested_directory)
          end
        end
      end
    )

    StandupMD.config.file.create = false
    file = StandupMD::File.find(earlier_file)

    assert_instance_of(StandupMD::File, file)
    assert_equal(::File.join(workdir, earlier_file), file.name)
  ensure
    active = false
  end

  def test_find_by_date
    assert_raise { StandupMD::File.find_by_date(fixtures["today_date"]) }
    file = StandupMD::File.find_by_date(Date.today)
    assert_instance_of(StandupMD::File, file)
    assert_equal(test_file_name, file.name)
    StandupMD.config.file.create = false
    assert_raise { StandupMD::File.find_by_date(Date.today.prev_year) }
    StandupMD.config.file.create = true
    assert_nothing_raised { StandupMD::File.find_by_date(Date.today.prev_year) }
  end

  def test_find_by_date_accepts_runtime_config
    runtime = StandupMD.config.file.copy
    runtime.directory = File.join(workdir, "runtime")
    runtime.name_format = "%Y-%m.markdown"
    runtime.create = true

    file = StandupMD::File.find_by_date(Date.today, config: runtime)

    assert_equal(
      File.join(runtime.directory, Date.today.strftime("%Y-%m.markdown")),
      file.name
    )
    refute_equal(runtime.directory, StandupMD.config.file.directory)
    assert_equal("%Y_%m.md", StandupMD.config.file.name_format)
  end

  def test_find_by_date_runtime_config_does_not_toggle_global_creation
    runtime = StandupMD.config.file.copy
    runtime.create = false
    missing = Date.today.prev_year

    assert_raise { StandupMD::File.find_by_date(missing, config: runtime) }
    assert(StandupMD.config.file.create)
  end

  def test_name
    assert_equal(test_file_name, @file.name)
  end

  def test_exist?
    assert(@file.exist?)
    FileUtils.rm(@file.name)
    refute(@file.exist?)
  end

  def test_load
    refute(@file.loaded?)
    assert_nothing_raised { @file.load }
    assert(@file.loaded?)
    file = @file.load
    assert_instance_of(StandupMD::File, file)
    entry_list = file.entries
    assert_instance_of(StandupMD::EntryList, entry_list)
    assert_equal(2, entry_list.size)
    StandupMD.config.file.current_header = "Today"
    assert_raise { @file.load }
  end

  def test_load_reads_file_before_parsing
    parser = Object.new
    parsed_entries = StandupMD::EntryList.new
    captured_text = nil
    parser.define_singleton_method(:parse) do |text|
      captured_text = text
      parsed_entries
    end
    @file.instance_variable_set(:@parser, parser)

    assert_same(@file, @file.load)
    assert_equal(::File.read(@file.name), captured_text)
    assert_same(parsed_entries, @file.entries)
  end

  def test_load_preserves_indented_markdown_tasks
    create_indented_standup_file

    entry = @file.load.entries.find(Date.today)

    assert_equal(
      [
        "Working issue number 1",
        "Did this supporting subtask",
        "Also did this thing",
        "Issue 2",
        "Another supporting task"
      ],
      entry.current
    )
    assert_equal([0, 1, 1, 0, 1], entry.current_tasks.map(&:indent_level))
  end

  def test_write
    @file.load
    assert(@file.write)
    refute(::File.zero?(@file.name))
    assert_nothing_raised { @file.load }
  end

  def test_write_renders_entries_before_writing_file
    entry = StandupMD::Entry.new(Date.today, ["Current"], [], [])
    parser = Object.new
    captured_entries = nil
    captured_dates = nil
    parser.define_singleton_method(:render) do |entries, **dates|
      captured_entries = entries
      captured_dates = dates
      "rendered markdown\n"
    end
    @file.instance_variable_set(:@entries, StandupMD::EntryList.new(entry))
    @file.instance_variable_set(:@parser, parser)

    assert(@file.write)
    assert_instance_of(StandupMD::EntryList, captured_entries)
    assert_equal({start_date: Date.today, end_date: Date.today}, captured_dates)
    assert_equal("rendered markdown\n", ::File.read(@file.name))
  end

  def test_write_preserves_indented_markdown_tasks
    create_indented_standup_file

    assert(@file.load.write)
    assert_equal(
      [
        "# #{Date.today.strftime(StandupMD.config.file.header_date_format)}",
        "## Previous",
        "- Yesterday",
        "## Current",
        "- Working issue number 1",
        "  - Did this supporting subtask",
        "  - Also did this thing",
        "- Issue 2",
        "  - Another supporting task",
        "## Impediments",
        "- None",
        ""
      ],
      ::File.read(@file.name).lines.map(&:chomp)
    )
  end

  def test_load_and_write_use_configured_indent_width
    StandupMD.config.file.indent_width = 4
    create_indented_standup_file(indent: 4)

    entry = @file.load.entries.find(Date.today)

    assert_equal([0, 1, 1, 0, 1], entry.current_tasks.map(&:indent_level))
    assert(@file.write)
    assert_match(
      /^    - Did this supporting subtask$/,
      ::File.read(@file.name)
    )
  end

  def create_indented_standup_file(indent: 2)
    nested_bullet = "#{" " * indent}-"
    ::File.open(@file.name, "w") do |f|
      f.puts "# #{Date.today.strftime(StandupMD.config.file.header_date_format)}"
      f.puts "## Previous"
      f.puts "- Yesterday"
      f.puts "## Current"
      f.puts "- Working issue number 1"
      f.puts "#{nested_bullet} Did this supporting subtask"
      f.puts "#{nested_bullet} Also did this thing"
      f.puts "- Issue 2"
      f.puts "#{nested_bullet} Another supporting task"
      f.puts "## Impediments"
      f.puts "- None"
    end
  end
end
