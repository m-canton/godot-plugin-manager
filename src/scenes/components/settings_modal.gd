class_name SettingsModal extends PanelContainer


signal saved()

enum Setting {
	GODOT_DIR,
	CATEGORIES,
}

const FILE_PATH := "user://settings.ini"
const CATEGORY = preload("res://src/scenes/components/settings_modal_category.tscn")

var settings_file: ConfigFile


func _ready() -> void:
	hide()
	_init_settings()
	%AddButton.pressed.connect(_on_add_button_pressed)
	%SaveButton.pressed.connect(save)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide()


func get_godot_dir() -> String:
	return settings_file.get_value("godot", "dir", "")


func get_categories() -> Array:
	var array := []
	if settings_file.has_section("categories"):
		for key in settings_file.get_section_keys("categories"):
			array.append([key, settings_file.get_value("categories", key)])
	return array


func save() -> Error:
	settings_file = ConfigFile.new()
	
	settings_file.set_value("godot", "dir", %GodotDirEdit.text)
	
	for c: SettingsModalCategory in %Categories.get_children():
		var key: String = c.get_category_name()
		if key.is_empty(): continue
		var path: String = c.get_category_path()
		if path.is_empty(): continue
		settings_file.set_value("categories", key, path)
	
	var error := settings_file.save(FILE_PATH)
	if error:
		push_error(error_string(error))
	else:
		print("Settings saved.")
		saved.emit()
	
	return error


func _init_settings() -> void:
	settings_file = ConfigFile.new()
	
	if settings_file.load(FILE_PATH) == OK:
		# Godot dir
		%GodotDirEdit.text = settings_file.get_value("godot", "dir", "")
		
		# Categories
		for key in settings_file.get_section_keys("categories"):
			var category: SettingsModalCategory
			category = CATEGORY.instantiate()
			if key == "plugins":
				category.set_category_name(key, false)
				category.set_removable(false)
			else:
				category.set_category_name(key)
			category.set_category_path(settings_file.get_value("categories", key))
			%Categories.add_child(category)
	else:
		var category := CATEGORY.instantiate()
		category.set_category_name("plugins", false)
		category.set_removable(false)
		%Categories.add_child(category)


func _on_add_button_pressed() -> void:
	var category: SettingsModalCategory = %Categories.get_child(%Categories.get_child_count() - 1)
	if not category.is_empty():
		category = CATEGORY.instantiate()
		%Categories.add_child(category)
