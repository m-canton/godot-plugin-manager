class_name MainControl extends Control


## Main Control.
## 
## Variant references to use them in different scripts.[br]
## Work in Progress: Settings Modal to edit category dirs. For now, use
## settigns.tscn to create settings.ini with category dirs.

## 0 uses now.
const CONFIG_FILE_PATH := "user://projects.ini"

static var plugins_path := ""

var _config_file := ConfigFile.new()
var _current_dir := ""

@onready var categories: HBoxContainer = $PanelContainer/VBoxContainer/ToolBar/Categories
@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/ProjectContainer/GridContainer
@onready var import_button: Button = $PanelContainer/VBoxContainer/ToolBar/HBoxContainer/ImportButton

func _ready() -> void:
	_on_settings_saved()
	
	%ProjectModal.open_requested.connect(godot_open)
	%SettingsModal.saved.connect(_on_settings_saved)
	%SettingsButton.pressed.connect(func(): %SettingsModal.show())
	
	import_button.pressed.connect(_on_import_plugins_pressed)
	
	_config_file.load(CONFIG_FILE_PATH)


func _save() -> Error:
	return _config_file.save(CONFIG_FILE_PATH)


func get_godot_path() -> String:
	if %VersionOptionButton.item_count > 0:
		return %VersionOptionButton.get_selected_metadata()
	return ""


func godot_open(project_path: String) -> void:
	var path: String = %VersionOptionButton.get_selected_metadata()
	if path.is_empty():
		push_error("Godot path is empty.")
		return
	
	OS.create_process(path, [project_path])


func _on_import_plugins_pressed() -> void:
	%ProjectModal.import_plugins(plugins_path)


func _on_settings_saved() -> void:
	_on_godot_dir_updated()
	_on_categories_updated()


func _on_godot_dir_updated() -> void:
	%VersionOptionButton.clear()
	var re := RegEx.create_from_string("^Godot_v(?<version>[0-9\\.]+)-(?<stable>[a-z0-9]+)_(?<os>.*)$")
	var dir_path: String = %SettingsModal.get_godot_dir()
	var dir := DirAccess.open(dir_path)
	
	var count := 0
	if dir and dir.list_dir_begin() == OK:
		var filename := dir.get_next()
		while not filename.is_empty():
			if not dir.current_is_dir():
				var result := re.search(filename)
				if result and not result.get_string("os").contains("console"):
					var text := result.get_string("version")
					var stable := result.get_string("stable")
					if stable != "stable":
						text += "-" + stable
					
					%VersionOptionButton.add_item(text)
					%VersionOptionButton.set_item_metadata(count, dir_path.path_join(filename))
					count += 1
			filename = dir.get_next()
	%VersionOptionButton.visible = count > 0


func _on_categories_updated() -> void:
	var button_group := ButtonGroup.new()
	button_group.pressed.connect(_on_category_pressed)
	import_button.disabled = true
	
	for c in categories.get_children():
		c.queue_free()
	
	for category in %SettingsModal.get_categories():
		var cname: String = category[0]
		var path: String = category[1]
		if not path.is_empty():
			if cname == "plugins":
				plugins_path = path
				import_button.disabled = false
			
			var button := Button.new()
			button.text = cname.capitalize()
			button.button_group = button_group
			button.toggle_mode = true
			button.set_meta("dir", path)
			categories.add_child(button)
	
	for c in categories.get_children():
		if not c.is_queued_for_deletion():
			_on_category_pressed(c)
			break


func _on_category_pressed(button: BaseButton) -> void:
	if not button.button_pressed:
		button.set_pressed_no_signal(true)
	
	var new_dir: String = button.get_meta("dir")
	if _current_dir == new_dir:
		return
	_current_dir = new_dir
	
	for c in grid_container.get_children():
		c.queue_free()
	
	for dirname in DirAccess.get_directories_at(_current_dir):
		var path := _current_dir.path_join(dirname + "/project.godot")
		if not FileAccess.file_exists(path):
			return
		
		var card := preload("res://src/scenes/components/project_card.tscn").instantiate()
		card.load_from_file(path)
		card.pressed.connect(_on_project_pressed.bind(path))
		grid_container.add_child(card)


func _on_project_pressed(path: String) -> void:
	%ProjectModal.show_project(path)
