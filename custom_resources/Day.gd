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


static func to_minutes(clock: String) -> int:
	var parts := clock.split(":")
	return int(parts[0]) * 60 + int(parts[1]) if parts.size() == 2 else -1


static func format_minutes(total: int) -> String:
	if total < 60:
		return "%d min" % total
	var hours := floori(total / 60.0)
	var rest := total % 60
	return "%d h" % hours if rest == 0 else "%d h %d min" % [hours, rest]


func start_time() -> String:
	return lessons[0].start_time if not lessons.is_empty() else ""


func end_time() -> String:
	var latest := -1
	for lesson in lessons:
		latest = maxi(latest, _end_minutes(lesson))
	return "%02d:%02d" % [floori(latest / 60.0), latest % 60] if latest >= 0 else ""


func gaps() -> Array[int]:
	var result: Array[int] = []
	var latest_end := -1
	for lesson in lessons:
		var start := to_minutes(lesson.start_time)
		result.append(maxi(start - latest_end, 0) if latest_end >= 0 and start >= 0 else 0)
		latest_end = maxi(latest_end, _end_minutes(lesson))
	return result


func total_break() -> int:
	var total := 0
	for gap in gaps():
		total += gap
	return total


func _end_minutes(lesson: Lesson) -> int:
	var end := to_minutes(lesson.end_time)
	return end if end >= 0 else to_minutes(lesson.start_time)


func weekday() -> String:
	var parts := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_string(date)))
	return WEEKDAYS[parts["weekday"]]


func pretty() -> String:
	var parts := date.split("-")
	if parts.size() != 3:
		return date
	return "%d %s %s" % [int(parts[2]), MONTHS[clampi(int(parts[1]) - 1, 0, 11)], parts[0]]
