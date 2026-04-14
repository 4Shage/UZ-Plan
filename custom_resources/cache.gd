class_name Cache extends ConfigFile

const DEFAULT_PATH: String = "user://sett.cfg"

func _init() -> void:
	_load()

## [method ConfigFile.load] with fallback to defaults.
func _load() -> void:
	var err = self.load(DEFAULT_PATH)
	if err != OK:
		print("No settings found, using defaults")
		self.load("res://defaultSett.cfg")

## [method ConfigFile.save] with default path.
func _save() -> void:
	save(DEFAULT_PATH)

## [method ConfigFile.set_value] that changes settings.
func _set_value(section: String, key: String, value: Variant) -> void:
	set_value(section,key,value)
	_change(section,key,value)
	_save()

func _change(_section: String, _key: String, _value: Variant) -> void:
	#match section:
	pass

## Static version of [method Settings._set_value].
static func static_set(section: String, key: String, value: Variant) -> void:
	var settings: Settings = Settings.new()
	settings._set_value(section, key, value)

## Static version of [method ConfigFile.get_value].
static func static_get(section: String, key: String, default: Variant = null) -> Variant:
	var settings: Settings = Settings.new()
	return settings.get_value(section, key, default)
