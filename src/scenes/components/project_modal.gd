extends ScrollContainer


const PLUGINS_FILE_PATH := "user://plugins.ini"


@onready var title_label: Label = $Modal/VBoxContainer/HBoxContainer/TitleLabel
@onready var plugins_button: Button = $Modal/VBoxContainer/HBoxContainer/PluginsButton

@onready var description_label: Label = $Modal/VBoxContainer/DescriptionLabel
@onready var plugin_buttons: GridContainer = $Modal/VBoxContainer/Plugins
@onready var link_button: Button = $Modal/VBoxContainer/LinkButton


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
	_plugins_file = ConfigFile.new()
	hide()
	_init_plugins()
	link_button.pressed.connect(_on_link_plugins_pressed)
	plugins_button.pressed.connect(_on_plugins_button_pressed)


func _init_plugins() -> Error:
	_plugins_file = ConfigFile.new()
	
	var error := _plugins_file.load(PLUGINS_FILE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return error
		
	if error:
		push_error(error_string(error))
		return error
	
	for c in plugin_buttons.get_children():
		c.queue_free()
	
	var array := _plugins_file.get_sections()
	array.sort()
	for plugin_name in array:
		var button := Button.new()
		button.text = plugin_name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("base_dir", _plugins_file.get_value(plugin_name, "path", ""))
		plugin_buttons.add_child(button)
	
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
					if dir.is_link(filename):
						print(filename, " is symbolic link. Skipped.")
					else:
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


func edit_project(path: String) -> Error:
	_project_file = ConfigFile.new()
	var error := _project_file.load(path)
	if error:
		push_error(error_string(error))
		return error
	
	show()
	_base_dir = path.get_base_dir()
	plugins_button.disabled = _addons_dir.is_empty()
	title_label.text = _project_file.get_value("application", "config/name", "")
	description_label.text = _project_file.get_value("application", "config/description", "")
	print("[", title_label.text, "]")
	
	for c: Button in plugin_buttons.get_children():
		c.button_pressed = false
		c.disabled = false
	
	%OtherPluginsLabel.text=""
	var dir := DirAccess.open(_addons_dir)
	if dir and dir.list_dir_begin() == OK:
		var filename := dir.get_next()
		while not filename.is_empty():
			if dir.current_is_dir():
				if dir.is_link(filename):
					print("+ ", filename)
					for c: Button in plugin_buttons.get_children():
						if c.text == filename:
							c.disabled = true
				else:
					print("- ", filename)
					print(%OtherPluginsLabel.text.is_empty())
					if %OtherPluginsLabel.text.is_empty():
						%OtherPluginsLabel.text = filename
					else:
						%OtherPluginsLabel.text += ", " + filename
			filename = dir.get_next()
	
	return OK


func _on_link_plugins_pressed() -> void:
	for c: Button in plugin_buttons.get_children():
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
					continue
			
			var projects_dir := DirAccess.open(MainControl.plugins_path)
			if projects_dir:
				var error := projects_dir.create_link(source_path, _addons_dir.path_join(c.text))
				if error:
					push_error(error_string(error))
				else:
					c.set_pressed_no_signal(false)
					c.disabled = true
					print(c.text, " plugin is linked.")


func _on_plugins_button_pressed() -> void:
	OS.shell_open(_addons_dir)
