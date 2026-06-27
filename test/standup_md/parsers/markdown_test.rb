# frozen_string_literal: true

require_relative "../../test_helper"

class TestMarkdownParser < TestHelper
  def setup
    super
    StandupMD.config.file.reset
    @parser = StandupMD::Parsers::Markdown.new
  end

  def test_parse
    entries = @parser.parse(
      <<~MARKDOWN
        # 2026-06-26
        ## Previous
        - Yesterday
        ## Current
        - Main task
          - Supporting task
        ## Impediments
        - None
      MARKDOWN
    )

    entry = entries.find(Date.new(2026, 6, 26))

    assert_instance_of(StandupMD::EntryList, entries)
    assert_equal(["Main task", "Supporting task"], entry.current)
    assert_equal([0, 1], entry.current_tasks.map(&:indent_level))
  end

  def test_parse_requires_exact_section_header
    error = assert_raise(StandupMD::Parsers::Markdown::Error) do
      @parser.parse(
        <<~MARKDOWN
          # 2026-06-26
          ## Currently
          - Main task
        MARKDOWN
      )
    end
    assert_match(/Unrecognized header \[Currently\]/, error.message)
  end

  def test_render_entry
    entry = StandupMD::Entry.new(
      Date.new(2026, 6, 26),
      [
        "Main task",
        StandupMD::Task.new("Supporting task", indent_level: 1)
      ],
      ["Yesterday"],
      ["None"]
    )

    assert_equal(
      <<~MARKDOWN,
        # 2026-06-26
        ## Previous
        - Yesterday
        ## Current
        - Main task
          - Supporting task
        ## Impediments
        - None

      MARKDOWN
      @parser.render_entry(entry)
    )
  end

  def test_render
    earlier = StandupMD::Entry.new(
      Date.new(2026, 6, 25),
      ["Earlier"],
      [],
      []
    )
    later = StandupMD::Entry.new(
      Date.new(2026, 6, 26),
      ["Later"],
      [],
      []
    )
    entries = StandupMD::EntryList.new(earlier, later)

    assert_equal(
      <<~MARKDOWN,
        # 2026-06-26
        ## Current
        - Later

        # 2026-06-25
        ## Current
        - Earlier

      MARKDOWN
      @parser.render(
        entries,
        start_date: Date.new(2026, 6, 25),
        end_date: Date.new(2026, 6, 26)
      )
    )
  end

  def test_render_uses_configured_markdown_format
    StandupMD.config.file.header_depth = 2
    StandupMD.config.file.sub_header_depth = 3
    StandupMD.config.file.current_header = "Today"
    StandupMD.config.file.previous_header = "Yesterday"
    StandupMD.config.file.bullet_character = "*"
    StandupMD.config.file.indent_width = 4
    StandupMD.config.file.header_date_format = "%m/%d/%Y"
    StandupMD.config.file.sub_header_order = %w[current previous impediments notes]
    entry = StandupMD::Entry.new(
      Date.new(2026, 6, 26),
      [StandupMD::Task.new("Supporting task", indent_level: 2)],
      ["Previous task"],
      []
    )

    assert_equal(
      <<~MARKDOWN,
        ## 06/26/2026
        ### Today
                * Supporting task
        ### Yesterday
        * Previous task

      MARKDOWN
      @parser.render_entry(entry)
    )
  end
end
