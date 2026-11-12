class_name Lesson
extends RefCounted

var uid := ""
var date := ""
var start_time := ""
var end_time := ""
var summary := ""
var teacher := ""
var categories := ""
var location := ""
var subgroups := PackedStringArray()


static func compare(a: Lesson, b: Lesson) -> bool:
	return [a.date, a.start_time, a.summary] < [b.date, b.start_time, b.summary]


static func deserialize(data: Dictionary) -> Lesson:
	var lesson := Lesson.new()
	lesson.uid = data.get("uid", "")
	lesson.date = data.get("date", "")
	lesson.start_time = data.get("start", "")
	lesson.end_time = data.get("end", "")
	lesson.summary = data.get("summary", "")
	lesson.teacher = data.get("teacher", "")
	lesson.categories = data.get("categories", "")
	lesson.location = data.get("location", "")
	lesson.subgroups = PackedStringArray(data.get("subgroups", []))
	return lesson


func serialize() -> Dictionary:
	return {
		"uid": uid,
		"date": date,
		"start": start_time,
		"end": end_time,
		"summary": summary,
		"teacher": teacher,
		"categories": categories,
		"location": location,
		"subgroups": Array(subgroups),
	}


func category_key() -> String:
	return categories.strip_edges().to_upper().replace("Ć", "C")


func matches(selected: PackedStringArray) -> bool:
	if selected.is_empty() or subgroups.is_empty():
		return true
	for subgroup in subgroups:
		if subgroup in selected:
			return true
	return false
