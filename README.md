# The Standup Doctor
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fevanthegrayt%2Fstandup_md%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/evanthegrayt/standup_md/goto?ref=master)
[![Gem Version](https://badge.fury.io/rb/standup_md.svg)](https://badge.fury.io/rb/standup_md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> The cure for all your standup woes.

A highly customizable and automated way to keep track of daily standups in
markdown files.

View on: [Github](https://github.com/evanthegrayt/standup_md) |
[GitHub Pages](https://evanthegrayt.github.io/standup_md/) |
[RubyGems](https://rubygems.org/gems/standup_md)

## Table of Contents
- [About](#about)
- [Installation](#Installation)
  - [Via RubyGems](#via-rubygems)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
  - [Command Line](#command-line)
    - [CLI Examples](#cli-examples)
      - [Adding an entry for today via editor](#adding-an-entry-for-today-via-editor)
      - [Copy the entry for today to clipboard](#copy-the-entry-for-today-to-clipboard)
      - [Add entry to file without opening it](#add-entry-to-file-without-opening-it)
      - [Find an entry by date and print it](#find-an-entry-by-date-and-print-it)
    - [Customization and Runtime Options](#customization-and-runtime-options)
    - [Using existing standup files](#using-existing-standup-files)
  - [API](#api)
    - [API Examples](#api-examples)
    - [Documentation](https://evanthegrayt.github.io/standup_md/doc/index.html)
- [Reporting Bugs and Requesting Features](#reporting-bugs-and-requesting-features)
- [Self-Promotion](#self-promotion)

## About
I've now been at two separate companies where we post our daily standups in a
chat client, such as Slack, Mattermost, or Riot. Typing out my standup every day
became tedious, as I'd have to look up what I did the day before, copy and paste
yesterday's work into a new entry, and add today's tasks. This gem automates
most of this process, along with providing means of opening the file in your
editor, and finding and displaying entries from the command line.

In a nutshell, calling `standup` from the command line will open a standup file
for the current month in your preferred editor. If an entry for today is already
present, no text will be generated. If an entry for today doesn't exist, one
will be generated with your preferred values. When generating, if a previous
entry exists, it will be added to today's entry as your previous day's work. See
[example](#example). There's also a very robust API if you'd like to use this
in your own code somehow.

## Installation
### Via RubyGems
Just install the gem!

```sh
gem install standup_md
```

To include in your project, add the following to your `Gemfile`.

```ruby
gem 'standup_md'
```

### Manual Installation
From your terminal, clone the repository where you want it, and use `rake` to
install the gem.

```sh
git clone https://github.com/evanthegrayt/standup_md.git
cd standup_md

# Use rake to build and install the gem.
rake install
```

## Usage
### Command Line
For the most basic usage, simply call the executable.

```sh
standup
```

This opens the current month's standup file. If an entry already exists for
today, nothing is added. If no entry exists for today, the previous "Current" is
placed in the "Previous" section of a new entry. The format of this file is very
important; you may add new entries, but don't change any of the headers. Doing
so will cause the parser to break. If you want to customize the headers, you can
do so in the [configuration file](#available-config-file-options-and-defaults).

### CLI Examples
#### Adding an entry for today via editor
For example, if the standup entry from yesterday reads as follows:

```markdown
# 2020-04-13
## Previous
- Did something else.
## Current
- Write new feature for `standup_md`
- Fix bug in `standup_md`
## Impediments
- None
```

The following scaffolding will be added for current entry at the top of the
file:

```markdown
# 2020-04-14
## Previous
- Write new feature for `standup_md`
- Fix bug in `standup_md`
## Current
- <!-- ADD TODAY'S WORK HERE -->
## Impediments
- None
```

#### Copy the entry for today to clipboard
There are also flags that will print entries to the command line. There's a full
list of features below, but as a quick example, you can copy today's entry to
your clipboard without even opening your editor.

```sh
standup -p | pbcopy
```

If you wanted to add today's entry without opening your editor, and print the
result to the command line, you could use the following.

#### Add entry to file without opening it
```sh
standup --no-edit --current "Work on this thing","And another thing"
```

#### Find an entry by date and print it.
If you wanted to find and print the entry for March 2nd, 2020, you could use the
following.

```sh
standup -p 2020-03-02
```

### Customization and Runtime Options
You can create a file in your home directory called `~/.standuprc`. Settings
located in this file will override default behavior. This file can also have
settings overwritten at runtime by the use of options. You can view [my config
file](https://github.com/evanthegrayt/dotfiles/blob/master/dotfiles/standuprc)
as an example. Any setting in this file can still be overridden at runtime by
passing flags to the executable.

You'll notice, a lot of settings don't have the ability to be changed at runtime
when calling the executable. This is because the file structure is very
important, and changing values that affect formatting will cause problems with
the file parser. If you don't want to use a default, make the change in your
config file before you start editing standups. There is an [open
issue](https://github.com/evanthegrayt/standup_md/issues/16) for handling this
for the user, but they're not available yet.

There are no options to change the headers at runtime because it uses the
headers to detect tasks from previous entries. If changed at runtime, this would
cause errors. For this reason, if you don't like the default headers, change
them in your configuration file after installation, and then try to not change
them again.


#### Available Config File Options and Defaults

```ruby
StandupMD.configure do |c|
  # Defaults for how the file is formatted.
  # See https://evanthegrayt.github.io/standup_md/doc/StandupMD/Config/Cli.html
  c.file.header_date_format = '%Y-%m-%d'
  c.file.header_depth       = 1
  c.file.sub_header_depth   = 2
  c.file.current_header     = 'Current'
  c.file.previous_header    = 'Previous'
  c.file.impediments_header = 'Impediments'
  c.file.notes_header       = 'Notes'
  c.file.sub_header_order   = %w[previous current impediments notes]
  c.file.directory          = ::File.join(ENV['HOME'], '.cache', 'standup_md')
  c.file.bullet_character   = '-'
  c.file.name_format        = '%Y_%m.md'
  c.file.create             = true

  # Defaults for entries
  # See https://evanthegrayt.github.io/standup_md/doc/StandupMD/Config/Entry.html
  c.entry.current          = ["<!-- ADD TODAY'S WORK HERE -->"]
  c.entry.previous         = []
  c.entry.impediments      = ['None']
  c.entry.notes            = []

  # Defaults for executable runtime behavior.
  # See https://evanthegrayt.github.io/standup_md/doc/StandupMD/Config/Cli.html
  c.cli.date               = Date.today
  c.cli.editor             = 'vim' # Checks $VISUAL and $EDITOR first, in that order
  c.cli.verbose            = false
  c.cli.edit               = true
  c.cli.write              = true
  c.cli.print              = false
  c.cli.auto_fill_previous = true
  c.cli.preference_file    = ::File.expand_path(::File.join(ENV['HOME'], '.standuprc'))
end
```

#### Executable Flags
```
    --current ARRAY            List of current entry's tasks
    --previous ARRAY           List of precious entry's tasks
    --impediments ARRAY        List of impediments for current entry
    --notes ARRAY              List of notes for current entry
    --sub-header-order ARRAY   The order of the sub-headers when writing the file
-f, --file-name-format STRING  Date-formattable string to use for standup file name
-E, --editor EDITOR            Editor to use for opening standup files
-d, --directory DIRECTORY      The directories where standup files are located
-w  --[no-]write               Write current entry if it doesn't exist. Default is true
-a  --[no-]auto-fill-previous  Auto-generate 'previous' tasks for new entries
-e  --[no-]edit                Open the file in the editor. Default is true
-v, --[no-]verbose             Verbose output. Default is false.
-p, --print [DATE]             Print current entry.
                               If DATE is passed, will print entry for DATE, if it exists.
                               DATE must be in the same format as file-name-format
```

Any options not set in this file will retain their default values. Note that if
you change `file_name_format`, and don't use a month or year, there will only
ever be one standup file. This could cause issues long-term, as the files will
get large over time and possibly cause performance issues.

#### Using Existing Standup Files
If you already have a directory of existing standup files, you can use them, but
they must be in a format that the parser can understand. The default is:

```markdown
# 2020-05-01
## Previous
- task
## Current
- task
## Impediments
- impediment
## Notes
- notes, if any are present
```

The order, words, date format, and header level are all customizable, but the
overall format must be the same. If customization is necessary, this must be
done in `~/.standuprc` before execution, or else the parser will error.

For example, if you wanted the format to be as follows:

```markdown
## 05/01/2020
### Today
* task
### Yesterday
* task
### Hold-ups
* impediment
### Notes
* notes, if any are present
```

Your `~/.standuprc` should contain:

```ruby
StandupMD.configure do |c|
  c.file.header_depth       = 2
  c.file.sub_header_depth   = 3
  c.file.current_header     = 'Today'
  c.file.previous_header    = 'Yesterday'
  c.file.impediments_header = 'Hold-ups'
  c.file.bullet_character   = '*'
  c.file.header_date_format = '%m/%d/%Y'
  c.file.sub_header_order   = %w[current previous impediments notes]
end
```

## API
The API is fully documented in the
[RDoc Documentation](https://evanthegrayt.github.io/standup_md/doc/index.html).

This was mainly written as a command line utility, but the API is ridiculously
robust, and is available for use in your own projects. A quick example of how
to write a new entry via code could look like the following:

### API Examples

```ruby
require 'standup_md'

StandupMD.configure do |c|
  c.file.current_header = 'Today',
end

file = StandupMD::File.find_by_date(Date.today)
entry = StandupMD::Entry.create { |e| e.current = ['Stuff I will do today'] }
file.entries << entry
file.write
```

The above example was written as such to show how the different pieces of the
API fit together. The code can actually be simplified to the following.

```ruby
require 'standup_md'

StandupMD.configure do |c|
  c.file.current_header = 'Today',
  c.entry.current = ['Stuff I will do today']
end

StandupMD::File.find_by_date(Date.today).load.write
```

## Reporting Bugs and Requesting Features
If you have an idea or find a bug, please [create an
issue](https://github.com/evanthegrayt/standup_md/issues/new). Just make sure the topic
doesn't already exist. Better yet, you can always submit a Pull Request.

## Self-Promotion
I do these projects for fun, and I enjoy knowing that they're helpful to people.
Consider starring [the repository](https://github.com/evanthegrayt/standup_md)
if you like it! If you love it, follow me [on
Github](https://github.com/evanthegrayt)!
