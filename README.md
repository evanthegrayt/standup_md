# The Standup Doctor
> The cure for all your standup woes.

A highly customizable and automated way to keep track of daily standups in
markdown files.

## Table of Contents
- [About](#about)
- [Installation](#Installation)
  - [Via RubyGems](#via-rubygems)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
  - [Example](#example)
  - [Customization and Runtime Options](#customization-and-runtime-options)
- [API](#api)
- [Reporting Bugs and Requesting Features](#reporting-bugs-and-requesting-features)
- [Self-Promotion](#self-promotion)

## About
I've now been at two separate companies where we post our daily standups in a
chat client, such as Slack, Mattermost, or Riot. Typing out my standup every day
became tedious, as I'd have to look up what I did the day before, copy and paste
yesterday's work into a new entry, and add today's tasks. This gem automates
most of this process, along with providing means of opening the file in your
editor, and displaying entries from the command line.

I wasn't sure that others would find this useful, but then the pandemic
happened, which I assume made doing standups via chat much more common.

In a nutshell, calling `standup` from the command line will open a standup file
for the current month in your preferred editor. If an entry for today is already
present, no text will be generated. If an entry for today doesn't exist, one
will be generated, and if a previous entry exists, it will be added to today's
entry as what your previous day's work. See [example](#example). There's also an
API if you'd like to use this in your own code somehow.

This is a new project, and I have a lot of updates planned (see the [issue
list](https://github.com/evanthegrayt/standup_md/issues)), but I won't push to
`master` unless all
[tests](https://github.com/evanthegrayt/standup_md/blob/master/test/standup_md_test.rb)
are passing and the gem is working as expected. The first official release will
be once [this milestone](https://github.com/evanthegrayt/standup_md/milestone/1)
is complete. Until then, consider this gem to be in alpha, and the version will
remain `< 0.1.0`.

## Installation
### Via RubyGems
*COMING SOON. For now, please use the [manual installation
instructions](#manual-installation). The gem will be officially released once
[this milestone](https://github.com/evanthegrayt/standup_md/milestone/1) is
completed*.

<!-- Just install the gem! -->

<!-- ```sh -->
<!-- gem install standup_md -->
<!-- ``` -->
<!-- If you don't have permission on your system to install ruby or gems, I recommend -->
<!-- using [rvm](https://rvm.io/) or -->
<!-- [rbenv](http://www.rubyinside.com/rbenv-a-simple-new-ruby-version-management-tool-5302.html), -->
<!-- or you can try to use a manual method below. -->


### Manual Installation
From your terminal, clone the repository where you want it. From there, you have
a couple of installation options.

```sh
git clone https://github.com/evanthegrayt/standup_md.git
cd standup_md

# Use rake to build and install the gem.
rake install

# OR manually link the executable somewhere. If you use this method, you cannot
# move the repository after you link it!
ln -s $PWD/bin/standup /usr/local/bin
```

## Usage
Call the executable.

```sh
standup
```

This opens the current month's standup file. If an entry already exists for
today, nothing is added. If no entry exists for today, the previous "Today" is
placed in the "Previous" section of a new entry.  The format of this file is
very important; do not change anything, except for adding entries for today.

### Example
For example, if the standup entry from yesterday reads as follows:

```markdown
# 2020-04-13
## Previous
- Did something else.
## Today
- Write new feature for `standup_md`
## Impediments
- None
```

The following scaffolding will be added for today:
```markdown
# 2020-04-14
## Previous
- Write new feature for `standup_md`
## Today
- <!-- ADD TODAY'S WORK HERE -->
## Impediments
- None
```

## Customization and Runtime Options
You can create a file in your home directory called `~/.standup_md.yml`.
Settings located in this file will override default behavior. This file can also
have settings overwritten at runtime by the use of options. Below is a table of
available settings and their defaults.

You'll notice, a lot of settings don't have the ability to be changed at
runtime. This is because the file structure is very important, and changing
values that affect formatting will cause problems with the file parser. If you
don't want to use a default, make the change in your config file before you
start editing standups. There is an [open
issue](https://github.com/evanthegrayt/standup_md/issues/16) for handling this
for the user, but they're not available yet.

|Runtime Flag|Config File Key|Default|Notes|
|:----|:------|:------|:------|
||`header_depth:`|`1`|Number of `#` to place before each entry header|
||`header_date_format:`|`%Y-%m-%d`|Will be prefixed with `# * header_depth`|
||`sub_header_depth:`|`2`|Number of `#` to place before each sub-header|
||`current_header:`|`Current`|Will be prefixed with `# * sub_header_depth`|
||`previous_header:`|`Previous`|Will be prefixed with `# * sub_header_depth`|
||`impediments_header:`|`Impediments`|Will be prefixed with `# * sub_header_depth`|
||`file_name_format:`|`%Y_%m.md`|String will be formatted by `strftime`|
||`bullet_character:`|`-` (dash)|Must be `-` (dash) or `*` (asterisk)|
|`-d DIRECTORY`|`directory:`|`~/.cache/standup_md`|Directory will be created if it doesn't exist|
|`-e EDITOR`|`editor:`|`$VISUAL`, `$EDITOR` or `vim`|In that order|
|`--current-entry-tasks=ARRAY`|`current_entry_tasks:`|`<!-- ADD TODAY'S WORK HERE -->`|Each entry will automatically be prefixed with `bullet_character`|
|`--previous-entry-tasks=ARRAY`|`previous_entry_tasks:`|The tasks from the previous entry|Each entry will automatically be prefixed with `bullet_character`|
|`--impediments=ARRAY`|`impediments:`|`None`|Each entry will automatically be prefixed with `bullet_character`|
|`--notes=ARRAY`|`notes:`|`nil`|Each entry will automatically be prefixed with `bullet_character`|
|`--sub-header-order=ARRAY`|`sub_header_order:`|`%w[previous current impediments notes]`|Elements must all exist.|
|`--[no-]edit`||`true`|Open the file in an editor|
|`--[no-]write`||`true`|Write today's entry to the file|
|`--[no-]previous-append`||`true`|When adding previous entries, append to previous tasks|
|`-t`||`false`|Output today's entry to the command line|
|`-a`||`false`|Output all entries (limit one month) to the command line|
|`-j`||`false`|When outputting to the terminal, output json instead of formatted markdown|
|`-v`||`false`|Verbose output|
|`-h`|||Print help|

For example, a custom `~/.standup_md.yml` file might contain the following.

```yaml
editor:            'mate'
current_header:    'Today'
previous_header:   'Yesterday'
directory:         '~/standups'
file_name_format:  'standups_for_%m_%Y.md'
```

Any options not set in this file will retain their default values. Note that if
you change `file_name_format`, and don't use a month or year, there will only
ever be one standup file. This could cause issues long-term, as the files will
get large over time and possibly cause performance issues.

Also, there are no options to change the headers at runtime because it uses the
headers to detect tasks from previous entries. If changed at runtime, this would
cause errors. For this reason, if you don't like the default headers, change
them in your configuration file after installation, and then try to not change
them again.

If you wanted to add some tasks at runtime, and without opening the file in an
editor, you could use the following:

```bash
standup --no-edit --current-entry-tasks="Work on this thing","And another thing!"
```

## API
This was mainly written as a command line utility, but I made the API available
for scripting. There are attribute accessors for most of the settings in the
[customization table](#customization-and-runtime-options) above. To view all
available methods, read the comments in the [source](lib/standup_md.rb). A
quick-and-dirty example of how to write a new entry via code could look like the
following:

```ruby
require 'standup_md'

standup = StandupMD.new do |s|
  s.current_entry_tasks = ['Thing to do today', 'Another thing to do today']
  s.impediments = ['Not enough time in the day']
end

standup.write
```

Entries are just hashes, so you can easily transform them to `json` objects.

```ruby
require 'standup_md'
require 'json'

standup = StandupMD.new
standup_entries_as_json = standup.all_entries.to_json
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
