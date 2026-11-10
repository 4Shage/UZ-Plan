extends Node

signal state_changed(text: String)
signal busy_changed(busy: bool)
signal courses_update
signal groups_update
signal lessons_update
signal subgroups_update

const BASE_URL := "https://plan.uz.zgora.pl/"

var list_of_courses := {}
var list_of_groups := {}
var lessons: Array[Lesson] = []
var course_id := ""
var group_id := ""
var subgroups := PackedStringArray()

var _settings := Settings.new()
var _cache := Cache.new()
var _pending := 0
var _refreshing := false


func start() -> void:
	_restore()
	await refresh()


func refresh() -> void:
	if _refreshing:
		return
	_refreshing = true
	await _load_courses()
	if not course_id.is_empty():
		await _load_groups(course_id)
	if not group_id.is_empty():
		await _load_lessons(group_id)
	_refreshing = false


func select_course(id: String) -> void:
	course_id = id
	group_id = ""
	subgroups = PackedStringArray()
	lessons.clear()
	list_of_groups = _cache.take("groups", id, {})
	_save_selection()
	groups_update.emit()
	lessons_update.emit()
	await _load_groups(id)


func select_group(id: String) -> void:
	group_id = id
	subgroups = PackedStringArray()
	lessons = _cache.take_lessons(id)
	_save_selection()
	lessons_update.emit()
	await _load_lessons(id)


func toggle_subgroup(label: String) -> void:
	var index := subgroups.find(label)
	if index >= 0:
		subgroups.remove_at(index)
	else:
		subgroups.append(label)
	_selection_changed()


func clear_subgroups() -> void:
	subgroups = PackedStringArray()
	_selection_changed()


func course_name() -> String:
	return list_of_courses.get(course_id, "")


func group_name() -> String:
	return list_of_groups.get(group_id, "")


func available_subgroups() -> Array:
	var found := {}
	for lesson in lessons:
		for label in lesson.subgroups:
			found[label] = true
	var result: Array = found.keys()
	result.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return result


func days() -> Array[Day]:
	var result: Array[Day] = []
	var current: Day = null
	for lesson in lessons:
		if not lesson.matches(subgroups):
			continue
		if current == null or current.date != lesson.date:
			current = Day.new(lesson.date)
			result.append(current)
		current.lessons.append(lesson)
	return result


func say(text: String) -> void:
	state_changed.emit(text)


func _selection_changed() -> void:
	_save_selection()
	subgroups_update.emit()


func _load_courses() -> void:
	var fresh := _links(await _download("grupy_lista_kierunkow.php"), "grupy_lista_grup_kierunku")
	if fresh.is_empty():
		say("Offline - showing saved data")
		return
	list_of_courses = fresh
	_cache.put("courses", "all", fresh)
	courses_update.emit()


func _load_groups(id: String) -> void:
	var fresh := _links(await _download("grupy_lista_grup_kierunku.php?ID=" + id), "grupy_plan")
	if id != course_id or fresh.is_empty():
		return
	list_of_groups = fresh
	_cache.put("groups", id, fresh)
	groups_update.emit()


func _load_lessons(id: String) -> void:
	var text := await _download("grupy_ics.php?ID=%s&KIND=GG" % id)
	if id != group_id or text.is_empty():
		return
	lessons = IcsParser.new().parse(text)
	_cache.put_lessons(id, lessons)
	_prune_subgroups()
	lessons_update.emit()
	say("Plan updated")


func _prune_subgroups() -> void:
	var available := available_subgroups()
	var kept := PackedStringArray()
	for label in subgroups:
		if label in available:
			kept.append(label)
	if kept.size() != subgroups.size():
		subgroups = kept
		_save_selection()


func _links(html: String, page: String) -> Dictionary:
	var result := {}
	var regex := RegEx.create_from_string(page + r'\.php\?ID=(\d+)"[^>]*>([^<]+)</a>')
	for found in regex.search_all(html):
		result[found.get_string(1)] = found.get_string(2).strip_edges().xml_unescape()
	return result


func _download(path: String) -> String:
	_set_busy(1)
	var http := HTTPRequest.new()
	http.use_threads = true
	http.timeout = 15.0
	http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)
	var text := ""
	if http.request(BASE_URL + path) == OK:
		var response: Array = await http.request_completed
		if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
			text = (response[3] as PackedByteArray).get_string_from_utf8()
	http.queue_free()
	_set_busy(-1)
	return text


func _set_busy(delta: int) -> void:
	_pending += delta
	if _pending == 1 and delta > 0:
		busy_changed.emit(true)
	elif _pending == 0:
		busy_changed.emit(false)


func _restore() -> void:
	course_id = str(_settings.take("plan", "course_id", ""))
	group_id = str(_settings.take("plan", "group_id", ""))
	if course_id == "0":
		course_id = ""
	if group_id == "0":
		group_id = ""
	subgroups = PackedStringArray(_settings.take("plan", "subgroups", []))
	list_of_courses = _cache.take("courses", "all", {})
	list_of_groups = _cache.take("groups", course_id, {})
	lessons = _cache.take_lessons(group_id)
	courses_update.emit()
	groups_update.emit()
	lessons_update.emit()


func _save_selection() -> void:
	_settings.set_value("plan", "course_id", course_id)
	_settings.set_value("plan", "group_id", group_id)
	_settings.set_value("plan", "subgroups", Array(subgroups))
	_settings.save(Settings.PATH)
