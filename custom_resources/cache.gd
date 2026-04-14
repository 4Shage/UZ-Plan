class_name Cache extends ConfigFile

const DEFAULT_PATH: String = "user://cache.cfg"

func course_save(courseID: int, groupID:int, list_of_lessons:Array[Day]):
	var data: Dictionary
	for lesson in list_of_lessons:
		data.merge(lesson.serialize(),false)
	_set_value(str(courseID),str(groupID),data)

func course_load(courseID: int, groupID:int, ) -> Array[Day]:
	var data: Dictionary = get_value(str(courseID),str(groupID),[])
	var list_of_lessons:Array[Day] = []
	for id in data.keys():
		var day: Day = Day.new(id,data[id])
		list_of_lessons.append(day)
	return list_of_lessons

func _init() -> void:
	_load()

## [method ConfigFile.load] with fallback to defaults.
func _load() -> void:
	var err = self.load(DEFAULT_PATH)
	if err != OK:
		print("No cache found")
## [method ConfigFile.save] with default path.
func _save() -> void:
	self.save(DEFAULT_PATH)

## [method ConfigFile.set_value] that changes settings.
func _set_value(section: String, key: String, value: Variant) -> void:
	print_debug("Cache set")
	set_value(section,key,value)
	_change(section,key,value)
	_save()

func _change(_section: String, _key: String, _value: Variant) -> void:
	#match section:
	pass

## Static version of [method Settings._set_value].
static func static_course_save(courseID: int, groupID:int, list_of_lessons:Array[Day]) -> void:
	var cache: Cache = Cache.new()
	cache.course_save(courseID, groupID, list_of_lessons)

## Static version of [method ConfigFile.get_value].
static func static_course_load(courseID: int, groupID:int) -> Array[Day]:
	var cache: Cache = Cache.new()
	return cache.course_load(courseID,groupID)
