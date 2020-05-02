var search_data = {"index":{"searchIndex":["standupmd","cli","append_previous?()","append_to_previous_entry_tasks()","bullet_character=()","config_file=()","config_file_loaded?()","current_entry_tasks=()","directory=()","echo()","edit()","edit?()","editor()","entry_previously_added?()","execute()","file_written?()","header_depth=()","impediments=()","json?()","load()","load()","load_config_file()","new()","new()","new_month?()","notes=()","previous_entry_tasks=()","print_all_entries()","print_all_entries?()","print_current_entry()","print_current_entry?()","reload()","should_append?()","standup()","sub_header_depth=()","sub_header_order()","sub_header_order=()","verbose?()","write()","write?()","write_file()","readme"],"longSearchIndex":["standupmd","standupmd::cli","standupmd::cli#append_previous?()","standupmd::cli#append_to_previous_entry_tasks()","standupmd#bullet_character=()","standupmd#config_file=()","standupmd#config_file_loaded?()","standupmd#current_entry_tasks=()","standupmd#directory=()","standupmd::cli#echo()","standupmd::cli#edit()","standupmd::cli#edit?()","standupmd::cli#editor()","standupmd#entry_previously_added?()","standupmd::cli::execute()","standupmd#file_written?()","standupmd#header_depth=()","standupmd#impediments=()","standupmd::cli#json?()","standupmd::load()","standupmd#load()","standupmd#load_config_file()","standupmd::new()","standupmd::cli::new()","standupmd#new_month?()","standupmd#notes=()","standupmd#previous_entry_tasks=()","standupmd::cli#print_all_entries()","standupmd::cli#print_all_entries?()","standupmd::cli#print_current_entry()","standupmd::cli#print_current_entry?()","standupmd#reload()","standupmd::cli#should_append?()","standupmd::cli#standup()","standupmd#sub_header_depth=()","standupmd#sub_header_order()","standupmd#sub_header_order=()","standupmd::cli#verbose?()","standupmd#write()","standupmd::cli#write?()","standupmd::cli#write_file()",""],"info":[["StandupMD","","StandupMD.html","","<p>The class for handing reading/writing of entries.\n<p>@example\n\n<pre class=\"ruby\"><span class=\"ruby-identifier\">su</span> = <span class=\"ruby-constant\">StandupMD</span>.<span class=\"ruby-identifier\">new</span>\n</pre>\n"],["StandupMD::Cli","","StandupMD/Cli.html","","<p>Class for handing the command-line interface.\n"],["append_previous?","StandupMD::Cli","StandupMD/Cli.html#method-i-append_previous-3F","()","<p>Should `previous_entry_tasks` be appended? If false, <code>previous_entry_tasks</code> will be overwritten.\n<p>@return …\n"],["append_to_previous_entry_tasks","StandupMD::Cli","StandupMD/Cli.html#method-i-append_to_previous_entry_tasks","()","<p>Appends entries passed at runtime to existing previous entries.\n<p>@return [Hash]\n"],["bullet_character=","StandupMD","StandupMD.html#method-i-bullet_character-3D","(character)","<p>Setter for bullet_character. Must be * (asterisk) or - (dash).\n<p>@param [String] character\n<p>@return [String] …\n"],["config_file=","StandupMD","StandupMD.html#method-i-config_file-3D","(config_file)","<p>Setter for directory. Must be expanded in case the user uses `~` for home. If the directory doesn&#39;t …\n"],["config_file_loaded?","StandupMD","StandupMD.html#method-i-config_file_loaded-3F","()","<p>Has a config file been loaded?\n<p>@return [Boolean]\n"],["current_entry_tasks=","StandupMD","StandupMD.html#method-i-current_entry_tasks-3D","(tasks)","<p>Setter for current entry tasks.\n<p>@param [Array] tasks\n<p>@return [Array]\n"],["directory=","StandupMD","StandupMD.html#method-i-directory-3D","(directory)","<p>Setter for directory. Must be expanded in case the user uses `~` for home. If the directory doesn&#39;t …\n"],["echo","StandupMD::Cli","StandupMD/Cli.html#method-i-echo","(msg)","<p>Prints output if <code>verbose</code> is true.\n<p>@return [nil]\n"],["edit","StandupMD::Cli","StandupMD/Cli.html#method-i-edit","()","<p>Opens the file in an editor. Abandons the script.\n"],["edit?","StandupMD::Cli","StandupMD/Cli.html#method-i-edit-3F","()","<p>Should the standup file be opened in the editor?\n<p>@return [Boolean] Default is true\n"],["editor","StandupMD::Cli","StandupMD/Cli.html#method-i-editor","()","<p>Tries to determine the editor, first by checking if the user has one set in their preferences. If not, …\n"],["entry_previously_added?","StandupMD","StandupMD.html#method-i-entry_previously_added-3F","()","<p>Was today&#39;s entry already in the file?\n<p>@return [boolean] true if today&#39;s entry was already in …\n"],["execute","StandupMD::Cli","StandupMD/Cli.html#method-c-execute","(options = [])","<p>Creates an instance of <code>StandupMD</code> and runs what the user requested.\n"],["file_written?","StandupMD","StandupMD.html#method-i-file_written-3F","()","<p>Has the file been written since instantiated?\n<p>@return [boolean]\n<p>@example\n"],["header_depth=","StandupMD","StandupMD.html#method-i-header_depth-3D","(depth)","<p>Number of octothorps (#) to use before the main header.\n<p>@param [Integer] depth\n<p>@return [Integer]\n"],["impediments=","StandupMD","StandupMD.html#method-i-impediments-3D","(tasks)","<p>Setter for impediments.\n<p>@param [Array] tasks\n<p>@return [Array]\n"],["json?","StandupMD::Cli","StandupMD/Cli.html#method-i-json-3F","()","<p>If printing an entry, should it be printed as json?\n<p>@return [Boolean] Default is false\n"],["load","StandupMD","StandupMD.html#method-c-load","(config_file = nil)","<p>Convenience method for calling <code>new</code> + <code>load</code>. Accepts a <code>YAML</code> config file as an argument, and yields the …\n"],["load","StandupMD","StandupMD.html#method-i-load","()","<p>Sets internal instance variables. Called when first instantiated, or after directory is set.\n<p>@return [self] …\n"],["load_config_file","StandupMD","StandupMD.html#method-i-load_config_file","()","<p>Loads the config file\n<p>@return [Hash] The config options\n"],["new","StandupMD","StandupMD.html#method-c-new","(config_file = nil)","<p>Constructor. Takes a path to a <code>YAML</code> configuration file as an argument. If passed, settings from the config …\n"],["new","StandupMD::Cli","StandupMD/Cli.html#method-c-new","(options)","<p>Constructor. Sets defaults.\n<p>@param [Array] options\n"],["new_month?","StandupMD","StandupMD.html#method-i-new_month-3F","()","<p>Is today a different month than the previous entry?\n"],["notes=","StandupMD","StandupMD.html#method-i-notes-3D","(tasks)","<p>Setter for notes.\n<p>@param [Array] notes\n<p>@return [Array]\n"],["previous_entry_tasks=","StandupMD","StandupMD.html#method-i-previous_entry_tasks-3D","(tasks)","<p>Setter for current entry tasks.\n<p>@param [Array] tasks\n<p>@return [Array]\n"],["print_all_entries","StandupMD::Cli","StandupMD/Cli.html#method-i-print_all_entries","()","<p>Prints all entries to the command line.\n<p>@return [nil]\n"],["print_all_entries?","StandupMD::Cli","StandupMD/Cli.html#method-i-print_all_entries-3F","()","<p>Should all entries be printed? If true, disables editing.\n<p>@return [Boolean] Default is false\n"],["print_current_entry","StandupMD::Cli","StandupMD/Cli.html#method-i-print_current_entry","()","<p>Prints the current entry to the command line.\n<p>@return [nil]\n"],["print_current_entry?","StandupMD::Cli","StandupMD/Cli.html#method-i-print_current_entry-3F","()","<p>Should current entry be printed? If true, disables editing.\n<p>@return [Boolean] Default is false\n"],["reload","StandupMD","StandupMD.html#method-i-reload","()","<p>Alias of <code>load</code>\n<p>@return [self]\n"],["should_append?","StandupMD::Cli","StandupMD/Cli.html#method-i-should_append-3F","()","<p>Did the user pass <code>previous_entry_tasks</code>, and should we append?\n<p>@return [Boolean]\n"],["standup","StandupMD::Cli","StandupMD/Cli.html#method-i-standup","()","<p>Sets up an instance of <code>StandupMD</code> and passes all user preferences.\n<p>@return [StandupMD]\n"],["sub_header_depth=","StandupMD","StandupMD.html#method-i-sub_header_depth-3D","(depth)","<p>Number of octothorps (#) to use before sub headers (Current, Previous, etc).\n<p>@param [Integer] depth\n<p>@return …\n"],["sub_header_order","StandupMD","StandupMD.html#method-i-sub_header_order","()","<p>Return a copy of the sub-header order so the user can&#39;t modify the array.\n<p>@return [Array]\n"],["sub_header_order=","StandupMD","StandupMD.html#method-i-sub_header_order-3D","(array)","<p>Preferred order for sub-headers.\n<p>@param [Array] Values must be %w[previous current impediment notes]\n<p>@return …\n"],["verbose?","StandupMD::Cli","StandupMD/Cli.html#method-i-verbose-3F","()","<p>Should debug info be printed?\n<p>@return [Boolean] Default is false\n"],["write","StandupMD","StandupMD.html#method-i-write","()","<p>Writes a new entry to the file if the first entry in the file isn&#39;t today.\n<p>@return [Boolean]\n"],["write?","StandupMD::Cli","StandupMD/Cli.html#method-i-write-3F","()","<p>Should the file be written?\n<p>@return [Boolean] Default is true\n"],["write_file","StandupMD::Cli","StandupMD/Cli.html#method-i-write_file","()","<p>Writes entries to the file.\n<p>@return [Boolean] true if file was written\n"],["README","","README_md.html","","<p>The Standup Doctor\n\n<blockquote><p>The cure for all your standup woes.\n</blockquote>\n<p>A highly customizable and automated way to keep …\n"]]}}