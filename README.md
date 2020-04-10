# The Standup Doctor
> The cure for all your standup woes.

An automated way to keep track of standups in markdown files.

## About
I've now been at two separate companies where we post our daily standups in a
chat client, such as Slack, Mattermost, Riot, etc.. Typing out my standup every
day became tedious, as I'd have to look up what I did the day before, copy and
paste yesterday's work into a new entry, and add today's tasks. This gem
automates most of this process.

I wasn't sure that others would find this useful, but then the pandemic
happened, which I assume made doing standups via chat much more common.

In a nutshell, calling `standup` from the command line will open a standup
file for the current month in your preferred editor. If an entry for today is
already present, no text will be generated. If an entry for today doesn't exist,
one will be generated, and if a previous entry exists, it will be added to
today's entry as what your previous day's work. See [usage](#usage) for
examples. There's also an API if you'd like to use this in your own code
somehow.

## Installation
### Via RubyGems
Just install the gem!

```sh
gem install standup_md
```

### Manual Installation
From your terminal, clone the repository where you want it, and link the
executable somewhere in your path.

```sh
git clone https://github.com/evanthegrayt/standup_md.git
cd standup_md
rake install # If using rake
# -OR-
ln -s $PWD/bin/standup /usr/local/bin # If NOT using rake
```

## Usage
Call the executable.

```sh
standup
```

This opens the current month's standup file. If an entry already exists for
today, nothing is added. If no entry exists for today, the previous "Today" is
placed in the "Previous" section of a new entry.

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

The format of this file is very important; do not change anything, except for
adding entries for today.

## Customization
You can create a file in your home directory called `~/.standup_md.yml`.
Settings located in this file will override default behavior. Below is a table
of available settings and their defaults.

|Setting|Default|Notes|
|:------|:------|:------|
|file_name_format|`%Y_%m.md`|String will be formatted by `strftime`|
|entry_header_format|`# %Y-%m-%d`|String will be formatted by `strftime`|
|current_header|`## Today`||
|previous_header|`## Previous`||
|impediment_header|`## Impediments`||
|directory|`~/.cache/standup_md`|Will create the directory if it doesn't exist|
|editor|`$VISUAL`, `$EDITOR` or `vim`|In that order|

For example, a custom `~/.standup_md.yml` file might contain the following.

```yaml
file_name_format: 'standups_for_%m_%Y.md'
previous_header: '## Yesterday'
editor: 'mate'
directory: '~/standups'
```

Any options not set in this file will retain their default values. Note that if
you change `file_name_format`, and don't use a month or year, there will only
ever be one standup file. This could cause issues long-term, as the files could
get large and possibly cause performance issues.

## API
This was mainly written as a command line utility, but I made the API available
for scripting. To view all available methods, read the comments in the
[source](lib/standup_md.rb). A quick-and-dirty example of how to write a new
entry via code could look like the following:

```ruby
require 'standup_md'

standup = StandupMD.new
standup.current_entry_tasks = ['Thing to do today', 'Another thing to do today']
standup.write
```
