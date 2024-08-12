extends PanelContainer

signal pressed

var _path := ""
var _project_file: ConfigFile

@onready var name_label: Label = $VBoxContainer/NameLabel

func save() -> Error:
	push_error("Cannot save the project.")
	return FAILED


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed and Rect2(Vector2.ZERO, size).has_point(event.position):
				pressed.emit()


func load_from_file(path: String) -> Error:
	_project_file = ConfigFile.new()
	var error := _project_file.load(path)
	if error:
		return error
	
	_path = path
	update_data.call_deferred()
	
	return OK


func update_data() -> void:
	name_label.text = _project_file.get_value("application", "config/name", "")
