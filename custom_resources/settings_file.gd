class_name Settings
extends ConfigFile

const PATH := "user://sett.cfg"


func _init() -> void:
	if FileAccess.file_exists(PATH):
		self.load(PATH)


func put(section: String, key: String, value: Variant) -> void:
	set_value(section, key, value)
	save(PATH)


func take(section: String, key: String, fallback: Variant = null) -> Variant:
	return get_value(section, key, fallback)
