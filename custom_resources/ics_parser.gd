class_name IcsParser
extends RefCounted

var _subgroup_regex := RegEx.create_from_string(r"\(PG:\s*([^)]*)\)")


func parse(text: String) -> Array[Lesson]:
	var lessons: Array[Lesson] = []
	var seen := {}
	for props in _events(_unfold(text)):
		var lesson := _to_lesson(props)
		if lesson == null or seen.has(lesson.uid):
			continue
		seen[lesson.uid] = true
		lessons.append(lesson)
	lessons.sort_custom(Lesson.compare)
	return lessons


func _unfold(text: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for raw in text.replace("\r\n", "\n").split("\n"):
		if raw.begins_with(" ") or raw.begins_with("\t"):
			if not lines.is_empty():
				var last := lines.size() - 1
				lines[last] = lines[last] + raw.substr(1)
		elif not raw.is_empty():
			lines.append(raw)
	return lines


func _events(lines: PackedStringArray) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var current := {}
	var inside := false
	for line in lines:
		if line == "BEGIN:VEVENT":
			current = {}
			inside = true
		elif line == "END:VEVENT":
			events.append(current)
			inside = false
		elif inside:
			var colon := line.find(":")
			if colon > 0:
				var key := line.substr(0, colon).get_slice(";", 0).to_upper()
				current[key] = line.substr(colon + 1)
	return events


func _to_lesson(props: Dictionary) -> Lesson:
	var dtstart: String = props.get("DTSTART", "")
	if dtstart.length() < 8:
		return null
	var lesson := Lesson.new()
	lesson.date = "%s-%s-%s" % [dtstart.substr(0, 4), dtstart.substr(4, 2), dtstart.substr(6, 2)]
	lesson.start_time = _clock(dtstart)
	lesson.end_time = _clock(props.get("DTEND", ""))
	lesson.categories = _text(props.get("CATEGORIES", ""))
	lesson.location = _text(props.get("LOCATION", ""))
	_read_summary(lesson, _text(props.get("SUMMARY", "")))
	lesson.uid = props.get("UID", "%s_%s_%s" % [lesson.date, lesson.start_time, lesson.summary])
	return lesson


func _read_summary(lesson: Lesson, summary: String) -> void:
	var found := _subgroup_regex.search(summary)
	if found:
		lesson.subgroups = _split_subgroups(found.get_string(1))
		summary = summary.replace(found.get_string(), "")
	var parts := summary.split(":", true, 1)
	lesson.summary = parts[0].strip_edges()
	if parts.size() > 1:
		lesson.teacher = parts[1].get_slice("(", 0).strip_edges()


func _split_subgroups(raw: String) -> PackedStringArray:
	var result := PackedStringArray()
	for part in raw.replace("/", ",").replace(";", ",").split(","):
		var label := part.strip_edges()
		if not label.is_empty() and not result.has(label):
			result.append(label)
	return result


func _clock(stamp: String) -> String:
	if stamp.length() < 13:
		return ""
	return "%s:%s" % [stamp.substr(9, 2), stamp.substr(11, 2)]


func _text(value: String) -> String:
	return value.replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\").strip_edges()
