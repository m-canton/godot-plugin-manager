class_name ProjectModal extends ScrollContainer


signal open_requested(path: String)

const PLUGINS_FILE_PATH := "user://plugins.ini"


var _plugins_file: ConfigFile
var _base_dir := "":
	set(value):
		if _base_dir != value:
			_base_dir = value
			if _base_dir.is_empty():
				_addons_dir = ""
			else:
				_addons_dir = _base_dir.path_join("addons")
				if not DirAccess.dir_exists_absolute(_addons_dir):
					_addons_dir = ""
var _addons_dir := ""
var _project_file: ConfigFile


func _ready() -> void:
	hide()
	_plugins_file = ConfigFile.new()
	_init_plugins()
	%LinkButton.pressed.connect(_on_link_plugins_pressed)
	%OpenAddonsButton.pressed.connect(_on_plugins_button_pressed)
	%OpenButton.hide() #TODO Check the project version.
	%OpenButton.pressed.connect(open_requested.emit.bind(_base_dir.path_join("project.godot")))


func _init_plugins() -> Error:
	_plugins_file = ConfigFile.new()
	
	var error := _plugins_file.load(PLUGINS_FILE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return error
		
	if error:
		push_error(error_string(error))
		return error
	
	for c in %PluginList.get_children():
		c.queue_free()
	
	var array := _plugins_file.get_sections()
	array.sort()
	for plugin_name in array:
		var button := Button.new()
		button.text = plugin_name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("base_dir", _plugins_file.get_value(plugin_name, "path", ""))
		%PluginList.add_child(button)
	
	return OK


func import_plugins(plugins_path: String) -> void:
	var plugin_cfg := ConfigFile.new()
	for dirname in DirAccess.get_directories_at(plugins_path):
		var addons_path = plugins_path.path_join(dirname).path_join("addons")
		var dir = DirAccess.open(addons_path)
		if dir and dir.list_dir_begin() == OK:
			var filename := dir.get_next()
			while not filename.is_empty():
				if dir.current_is_dir():
					if not dir.is_link(filename):
						var plugin_path := addons_path.path_join(filename)
						var error := plugin_cfg.load(plugin_path.path_join("plugin.cfg"))
						if error:
							push_error(error_string(error))
						else:
							_plugins_file.set_value(filename, "name", plugin_cfg.get_value("plugin", "name", ""))
							_plugins_file.set_value(filename, "description", plugin_cfg.get_value("plugin", "description", ""))
							_plugins_file.set_value(filename, "version", plugin_cfg.get_value("plugin", "version", "0.0"))
							_plugins_file.set_value(filename, "path", plugin_path)
				filename = dir.get_next()
	
	_plugins_file.save(PLUGINS_FILE_PATH)
	_init_plugins()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide()


func show_project(path: String) -> Error:
	_project_file = ConfigFile.new()
	var error := _project_file.load(path)
	if error:
		push_error(error_string(error))
		return error
	
	show()
	_base_dir = path.get_base_dir()
	%OpenAddonsButton.disabled = _addons_dir.is_empty()
	%TitleLabel.text = _project_file.get_value("application", "config/name", "")
	%DescriptionLabel.text = _project_file.get_value("application", "config/description", "")
	
	for c: Button in %PluginList.get_children():
		c.button_pressed = false
		c.disabled = false
	
	%OtherPluginsLabel.text = ""
	var dir := DirAccess.open(_addons_dir)
	if dir and dir.list_dir_begin() == OK:
		var filename := dir.get_next()
		while not filename.is_empty():
			if dir.current_is_dir():
				var plugin_exists := false
				for c: Button in %PluginList.get_children():
					if c.text == filename:
						c.disabled = true
						plugin_exists = true
				
				if not dir.is_link(filename):
					if not %OtherPluginsLabel.text.is_empty():
						%OtherPluginsLabel.text += ", "
					%OtherPluginsLabel.text += filename + ("*" if plugin_exists else "")
			filename = dir.get_next()
	
	return OK


func _on_link_plugins_pressed() -> void:
	var new_plugins := PackedStringArray()
	
	for c: Button in %PluginList.get_children():
		if not c.disabled and c.button_pressed:
			var source_path: String = c.get_meta("base_dir", "")
			if source_path.is_empty():
				push_error("Plugin base dir is empty.")
				continue
			
			if _addons_dir.is_empty():
				_addons_dir = _base_dir.path_join("addons")
				var error := DirAccess.make_dir_absolute(_addons_dir)
				if error:
					push_error(error_string(error))
					_addons_dir = ""
					return
			
			var projects_dir := DirAccess.open(MainControl.plugins_path)
			if projects_dir:
				var error := projects_dir.create_link(source_path, _addons_dir.path_join(c.text))
				if error:
					push_error(error_string(error))
				else:
					new_plugins.append(c.text)
					c.set_pressed_no_signal(false)
					c.disabled = true
	
	_add_plugins_to_gitignore(new_plugins)


func _add_plugins_to_gitignore(new_plugins: PackedStringArray) -> void:
	if new_plugins.is_empty():
		return
	
	var gitignore := ""
	var gitignore_path := _addons_dir.path_join(".gitignore")
	if FileAccess.file_exists(gitignore_path):
		gitignore = FileAccess.get_file_as_string(gitignore_path)
	
	new_plugins.sort()
	var lines: PackedStringArray = [] if gitignore.is_empty() else gitignore.split("\n")
	var line_count := lines.size()
	var has_plugin_section := false
	var i := 0
	var pi := 0
	var pname := new_plugins[pi] + "/"
	var pcount := new_plugins.size()
	while i < line_count:
		var line := lines[i]
		if has_plugin_section:
			if line.is_empty() or line.begins_with("#"):
				break
			elif line >= pname:
				if line != pname:
					lines.insert(i, pname)
				pi += 1
				if pi >= pcount:
					break
				pname = new_plugins[pi] + "/"
				continue
		elif line == "# Plugin Manager":
			has_plugin_section = true
		i += 1
	
	if not has_plugin_section:
		if not lines.is_empty():
			lines.append("")
		lines.append("# Plugin Manager")
	
	while pi < pcount:
		lines.append(new_plugins[pi] + "/")
		pi += 1
	
	var file := FileAccess.open(gitignore_path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
	else:
		push_error(error_string(FileAccess.get_open_error()))


func _on_plugins_button_pressed() -> void:
	OS.shell_open(_addons_dir)
