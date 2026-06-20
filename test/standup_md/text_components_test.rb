# frozen_string_literal: true

require_relative "../test_helper"

class TestTextComponents < TestHelper
  def setup
    super
    StandupMD.config.file.reset
  end

  def test_task
    task = StandupMD::Task.new("Supporting task", indent_level: 1)

    assert_equal("Supporting task", task.to_s)
    assert_equal("  - Supporting task", task.to_markdown)
  end

  def test_task_uses_configured_indent_width
    StandupMD.config.file.indent_width = 4

    task = StandupMD::Task.new("Supporting task", indent_level: 2)

    assert_equal("        - Supporting task", task.to_markdown)
  end

  def test_section
    StandupMD.config.file.current_header = "Today"
    section = StandupMD::Section.new(
      :current,
      [
        "Main task",
        StandupMD::Task.new("Supporting task", indent_level: 1)
      ]
    )

    assert_equal("Today", section.to_s)
    assert_equal(
      [
        "## Today",
        "- Main task",
        "  - Supporting task"
      ],
      section.to_markdown
    )
  end

  def test_title
    title = StandupMD::Title.new(Date.new(2026, 6, 19))

    assert_equal("2026-06-19", title.to_s)
    assert_equal("# 2026-06-19", title.to_markdown)
  end
end
