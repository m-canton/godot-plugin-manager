class_name SettingsModal extends PanelContainer


signal saved

const FILE_PATH := "user://settings.ini"
const CATEGORY = preload("res://src/scenes/components/settings_modal_category.tscn")

var settings_file: ConfigFile


func _ready() -> void:
	settings_file = ConfigFile.new()
	if settings_file.load(FILE_PATH) == OK:
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
	%AddButton.pressed.connect(_on_add_button_pressed)
	%SaveButton.pressed.connect(_on_saved_button_pressed)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide()


func get_categories() -> Array:
	var array := []
	if settings_file.has_section("categories"):
		for key in settings_file.get_section_keys("categories"):
			array.append([key, settings_file.get_value("categories", key)])
	return array


func _on_add_button_pressed() -> void:
	var category: SettingsModalCategory = %Categories.get_child(%Categories.get_child_count() - 1)
	if not category.is_empty():
		category = CATEGORY.instantiate()
		%Categories.add_child(category)


func _on_saved_button_pressed() -> void:
	settings_file = ConfigFile.new()
	
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
