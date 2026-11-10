class_name Cache
extends ConfigFile

const PATH := "user://cache.cfg"


func _init() -> void:
	if FileAccess.file_exists(PATH):
		self.load(PATH)


func put(section: String, key: String, value: Variant) -> void:
	set_value(section, key, value)
	save(PATH)


func take(section: String, key: String, fallback: Variant = null) -> Variant:
	return get_value(section, key, fallback)


func put_lessons(group_id: String, lessons: Array[Lesson]) -> void:
	put("lessons", group_id, lessons.map(func(lesson: Lesson) -> Dictionary: return lesson.serialize()))


func take_lessons(group_id: String) -> Array[Lesson]:
	var result: Array[Lesson] = []
	for data: Dictionary in take("lessons", group_id, []):
		result.append(Lesson.deserialize(data))
	return result
