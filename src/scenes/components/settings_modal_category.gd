class_name SettingsModalCategory extends HBoxContainer



func _ready() -> void:
	%RemoveButton.pressed.connect(queue_free)
	%UpButton.pressed.connect(func():
		var parent := get_parent()
		var index := get_index()
		if index > 0:
			index -= 1
			parent.move_child(self, index)
	)
	%DownButton.pressed.connect(func():
		var parent := get_parent()
		var index := get_index()
		if index < parent.get_child_count() - 1:
			index += 1
			parent.move_child(self, index)
	)


func is_empty() -> bool:
	return get_category_name().is_empty() and get_category_path().is_empty()


func set_removable(value: bool):
	%RemoveButton.disabled = not value


func set_category_name(value: String, editable := true):
	%NameEdit.text = value
	%NameEdit.editable = editable


func get_category_name() -> String:
	return %NameEdit.text


func set_category_path(value: String):
	%PathEdit.text = value


func get_category_path() -> String:
	return %PathEdit.text
