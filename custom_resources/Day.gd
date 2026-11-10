class_name Day
extends RefCounted

const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var date: String
var lessons: Array[Lesson] = []


func _init(idate: String) -> void:
	date = idate


static func today() -> String:
	return Time.get_date_string_from_system()


func weekday() -> String:
	var parts := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_string(date)))
	return WEEKDAYS[parts["weekday"]]


func pretty() -> String:
	var parts := date.split("-")
	if parts.size() != 3:
		return date
	return "%d %s %s" % [int(parts[2]), MONTHS[clampi(int(parts[1]) - 1, 0, 11)], parts[0]]
