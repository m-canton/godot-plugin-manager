extends Node


## Toggle save call comment to create config file. I recommend that you leave
## the line commented once you are done to avoid overwriting it by mistake.
func _ready() -> void:
	var config_file := ConfigFile.new()
	
	var categories := {
		"plugins": "",
		"projects": "",
	}
	
	for key in categories:
		config_file.set_value("categories", key, categories[key])
	
	#config_file.save(SETTINGS_FILE_PATH)
