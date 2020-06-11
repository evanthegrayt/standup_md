require_relative '../test_helper'
require_relative '../../lib/standup_md'

class TestEntryList < TestHelper
  def setup
    super
    @entry_one = StandupMD::Entry.new(
      Date.today.prev_day.prev_day,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
    )
    @entry_two = StandupMD::Entry.new(
      Date.today.prev_day,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
      ['Notes'],
    )
    @entry_three = StandupMD::Entry.new(
      Date.today,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
      ['Notes'],
    )
    @entry_list = StandupMD::EntryList.new(@entry_one)
  end

  def test_initialize
    assert_nothing_raised { StandupMD::EntryList.new(@entry_one, @entry_two) }
    assert_raise { StandupMD::EntryList.new('string') }
  end

  def test_each(&block)
    assert_respond_to(@entry_list, :each)
    assert_nothing_raised do
      @entry_list.each { |i| assert_instance_of(StandupMD::Entry, i) }
    end
  end

  def test_append_and_size
    assert_equal(1, @entry_list.size)
    assert_nothing_raised { @entry_list << @entry_two }
    assert_equal(2, @entry_list.size)
    assert_raise { @entry_list << [] }
  end

  def test_find
    assert_nil(@entry_list.find(@entry_three.date))
    assert_equal(@entry_one, @entry_list.find(@entry_one.date))
  end

  def test_sort
    s = StandupMD::EntryList.new(@entry_two, @entry_one)
    assert_equal([@entry_one, @entry_two], s.sort.to_a)
    assert_instance_of(StandupMD::EntryList, @entry_list.sort)
  end

  def test_sort!
    s = StandupMD::EntryList.new(@entry_two, @entry_one)
    assert_nothing_raised { s.sort! }
    assert_equal([@entry_one, @entry_two], s.to_a)
    assert_instance_of(StandupMD::EntryList, @entry_list.sort!)
  end

  def test_sort_reverse
    s = StandupMD::EntryList.new(@entry_one, @entry_two)
    assert_equal([@entry_two, @entry_one], s.sort_reverse.to_a)
    assert_instance_of(StandupMD::EntryList, @entry_list.sort_reverse)
  end

  def test_filter
    @entry_list << @entry_two
    @entry_list << @entry_three
    @entry_list.sort!
    assert_equal(3, @entry_list.size)
    assert_equal(2, @entry_list.filter(@entry_one.date, @entry_two.date).size)
    assert_equal(3, @entry_list.size)
    assert_nothing_raised do
      @entry_list.filter!(@entry_one.date, @entry_two.date).size
    end
    assert_equal(2, @entry_list.size)
    assert_instance_of(StandupMD::EntryList, @entry_list.filter(@entry_one.date, @entry_two.date))
    assert_instance_of(StandupMD::EntryList, @entry_list.filter!(@entry_one.date, @entry_two.date))
  end

  def test_first
    @entry_list << @entry_two
    @entry_list << @entry_three
    assert_equal(@entry_one, @entry_list.sort.first)
    assert_instance_of(StandupMD::Entry, @entry_list.first)
  end

  def test_last
    @entry_list << @entry_two
    @entry_list << @entry_three
    assert_equal(@entry_three, @entry_list.sort.last)
    assert_instance_of(StandupMD::Entry, @entry_list.last)
  end

  def test_to_h
    assert_instance_of(Hash, @entry_list.to_h)
    assert_equal(
      {Date.today.prev_day.prev_day =>
       {"current" => ["Current task"],
        "previous" => ["Previous task"],
        "impediments" => ["Impediment"],
        "notes" => []
       }},
      @entry_list.to_h
    )
  end

  def test_empty?
    assert_empty(StandupMD::EntryList.new)
  end

  def test_to_json
    assert_instance_of(String, @entry_list.to_json)
    assert_equal(
      "{\"#{Date.today.prev_day.prev_day}\":{\"current\":[\"Current task\"],\"previous\":[\"Previous task\"],\"impediments\":[\"Impediment\"],\"notes\":[]}}",
      @entry_list.to_json
    )
  end
end
