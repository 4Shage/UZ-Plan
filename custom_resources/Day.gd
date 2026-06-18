class_name Day
extends Resource

@export var date: Dictionary
@export var lessons: Dictionary[String,Lesson]
@export var weekday: Time.Weekday

func _init(idate:String, ilessons:Dictionary) -> void:
	var time = Time.get_datetime_dict_from_datetime_string(idate,true)
	for key in time.keys():
		match key:
			"hour","minute","second": pass
			"weekday": weekday = time["weekday"]
			var e: date[e] = time[e]
	for lesson in ilessons.keys():
		var object: Lesson = Lesson.new(ilessons[lesson])
		lessons[lesson] = object

func getStringDate() -> String:
	return _getStringDate(date)
static func _getStringDate(d:Dictionary) -> String:
	if d.is_empty(): return ""
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func serialize() -> Dictionary:
	var idate:String = getStringDate()
	var ilessons:Dictionary[String,Dictionary]
	for lesson in lessons:
		var dict = lessons[lesson].serialize()
		ilessons.merge(dict)
	return {idate:ilessons}
