require 'yaml'
require 'date'
require 'fileutils'

class Standup
  STANDUP_DIR = File.join(__dir__, '..', 'standups')

  def file
    @file ||= File.expand_path(File.join(
      STANDUP_DIR,
      "#{today.strftime(prefs['file_date_format'])}.md"
    ))
  end

  def add_new_entry
    return false if new_entry_added?

    yesterday = false
    File.foreach(previous_file) do |line|
      break if line.strip.downcase.include?('impediments')
      new_entry << line if yesterday
      yesterday = true if line.strip.downcase.include?('today')
    end

    new_entry.concat(new_entry_scaffolding)

    write_file
  end

  def write_file
    all_previous_entries = File.read(previous_file)
    File.open(file, 'w') do |f|
      f.puts new_entry
      f.puts all_previous_entries
    end
  end

  def editor
    @editor ||= prefs.fetch('editor', 'vim')
  end

  private

  def previous_file
    @previous_file ||=
      if File.file?(file)
        file
      else
        FileUtils.touch(file)
        prev_month_file = File.join(STANDUP_DIR, "#{today.prev_month.strftime('%Y_%m')}.md")
        prev_month_file if File.file?(prev_month_file)
      end
  end

  def today
    @today ||= Date.today
  end

  def prefs
    return @prefs if @prefs

    repo_file = File.join(__dir__, '..', 'config', 'preferences.yml')
    user_file = File.expand_path(File.join('~', '.standups.yml'))

    prefs = YAML.load_file(repo_file)
    prefs.merge!(YAML.load_file(user_file)) if File.file?(user_file)

    @prefs = prefs
  end

  def new_entry_scaffolding
    @new_entry_scaffolding ||= [
      '## Today',
      "- <!-- ADD TODAY'S WORK HERE -->",
      '## Impediments',
      '- None',
      ''
    ]
  end

  def header
    @header ||= '# ' << today.strftime(prefs['header_date_format'])
  end

  def new_entry
    @new_entry ||= [
      header,
      '## Previous',
    ]
  end

  def new_entry_added?
    header.include?(File.open(file, &:readline).strip)
  end
end
