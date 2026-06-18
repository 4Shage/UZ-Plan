extends Node
signal internet
signal state_changed(text:String)
signal courses_update
signal groups_update
signal subgroups_update
signal lessons_update

const LIST_OF_COURSES:String = "https://plan.uz.zgora.pl/grupy_lista_kierunkow.php"

var loading_settings: bool = false

var state:String:
	set(value):
		state = value
		print(state)
		state_changed.emit(state)
var list_of_courses:Dictionary:
	set(value):
		list_of_courses = value
		Settings.static_set("plan","courses",list_of_courses)
		courses_update.emit()
var list_of_groups:Dictionary:
	set(value):
		list_of_groups = value
		Settings.static_set("plan","groups",list_of_groups)
		groups_update.emit()
var data:Dictionary:
	set(value):
		Settings.static_set("plan","lessons",value)
		data = value
		lessons_update.emit()
var list_of_lessons:Array[Day]:
	set(value):
		if course_id > 0 and group_id > 0:
			Cache.static_course_save(course_id,group_id,value)
		list_of_lessons = value
var course_id: int:
	set(value):
		course_id = value
		Settings.static_set("plan","course_id",course_id)
		if not loading_settings:
			get_course_groups()
var group_id:int:
	set(value):
		group_id = value
		Settings.static_set("plan","group_id",group_id)
		load_cached_lessons()
		if not loading_settings:
			get_lessons()
var subgroup_id:String:
	set(value):
		subgroup_id = value
		Settings.static_set("plan","subgroup_id",subgroup_id)

func prepare_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	http.use_threads = true
	http.timeout = 10
	http.set_tls_options(TLSOptions.client_unsafe())
	return http

func check_net() -> void:
	var http := prepare_http()
	http.request_completed.connect(func(..._args): 
		internet.emit()
		http.queue_free()
		)
	self.add_child(http)
	var request_error := http.request("https://www.google.com")
	if request_error != OK:
		http.queue_free()
		internet.emit()

func get_download_fallback(file_name:String) -> String:
	print("Using defaults")
	var default_file:String = file_name.replace("user://","res://default_assets/")
	if FileAccess.file_exists(default_file):
		return default_file
	push_error("Could not download file and default does not exist: " + file_name)
	return ""

func download(link:String,ext:String,override_name:String = "") -> String:
	var http := prepare_http()
	var file_name:String = "user://"+((link.get_slice("/",link.get_slice_count("/")-1) + "." + ext) if override_name.is_empty() else (override_name + "." + ext))
	http.download_file = file_name
	self.add_child(http)
	var request_error := http.request(link,[],HTTPClient.METHOD_GET,"")
	if request_error != OK:
		push_error("Could not start download request: " + link)
		http.queue_free()
		return get_download_fallback(file_name)
	var a:Array = await http.request_completed
	#while a[1] != 200:
		#http.request(link,[],HTTPClient.METHOD_GET,"")
		#a = await http.request_completed
		#print(a[1])
	print(a[1])
	http.queue_free()
	if FileAccess.file_exists(file_name):
		print(file_name+" was downloaded!")
		return file_name
	return get_download_fallback(file_name)

func load_cached_lessons() -> bool:
	if course_id <= 0 or group_id <= 0:
		return false
	var cached_lessons := Cache.static_course_load(course_id, group_id)
	if cached_lessons.is_empty():
		return false
	list_of_lessons = cached_lessons
	state = "Loaded cached lessons.."
	lessons_update.emit()
	return true

func start() -> void:
	loading_settings = true
	if Settings.static_get("plan","course_id") != null:
		course_id = Settings.static_get("plan","course_id")
	if Settings.static_get("plan","group_id") != null:
		group_id = Settings.static_get("plan","group_id")
	if Settings.static_get("plan","subgroup_id") != null:
		subgroup_id = Settings.static_get("plan","subgroup_id")
		subgroups_update.emit()
	loading_settings = false

	check_net()
	await internet
	state = "Checking plan..."
	var file := FileAccess.open(await download(LIST_OF_COURSES,"html"), FileAccess.READ)
	if not file:
		push_error("Could not open courses file")
		return
	var regex = RegEx.new()
	
	regex.compile(r'grupy_lista_grup_kierunku\.php\?ID=(\d+)')
	var courses_ids:Array = regex.search_all(file.get_as_text())
	regex.compile(r'grupy_lista_grup_kierunku\.php\?ID=\d+">([^<]+)</a>')
	var courses_names:Array = regex.search_all(file.get_as_text())
	file.close()
	for id:RegExMatch in courses_ids:
		list_of_courses[id.strings[1]] = courses_names[courses_ids.find(id)].strings[1]
	courses_update.emit()
	state = "Acquired courses.."
	if course_id > 0:
		get_course_groups()
	if group_id > 0:
		get_lessons()


func get_course_groups() -> void:
	if course_id <= 0: return
	state = "Getting courses..."
	list_of_groups.clear()
	var regex = RegEx.new()
	var course_file := FileAccess.open(await download("https://plan.uz.zgora.pl/grupy_lista_grup_kierunku.php?ID="+str(course_id),"html","groups"),FileAccess.READ)
	if not course_file:
		push_error("Could not open groups file")
		return
	regex.compile(r'grupy_plan\.php\?ID=(\d+)">([^<]+)</a>')
	for m in regex.search_all(course_file.get_as_text()):
		list_of_groups[m.get_string(1)] = m.get_string(2).strip_edges()
	course_file.close()
	groups_update.emit()

func get_lessons() -> void:
	if group_id <= 0:
		return
	state = "Getting lessons..."
	data.clear()
	var url = "https://plan.uz.zgora.pl/grupy_ics.php?ID={0}&KIND=GG".format([group_id])
	var group_file := FileAccess.open(await download(url, "ics", "plan"), FileAccess.READ)
	if not group_file:
		load_cached_lessons()
		push_error("Nie można otworzyć pliku planu")
		return

	var content = group_file.get_as_text()
	group_file.close()

	# Scal linie kontynuacji
	var merged_lines: PackedStringArray = []
	var prev_line := ""
	for line in content.split("\n"):
		if line.begins_with(" ") or line.begins_with("\t"):
			prev_line += line.strip_edges()
		else:
			if prev_line != "":
				merged_lines.append(prev_line)
			prev_line = line.strip_edges()
	if prev_line != "":
		merged_lines.append(prev_line)

	var current_event: Dictionary = {}
	var in_event := false

	for line in merged_lines:
		if line == "BEGIN:VEVENT":
			current_event = {}
			in_event = true
			continue
		elif line == "END:VEVENT":
			in_event = false

			# Dodaj tylko eventy z datą
			if current_event.has("DTSTART"):
				var dtstart = current_event["DTSTART"]
				var dtend = current_event.get("DTEND", "")

				var date = dtstart.substr(0, 8)
				var date_formatted = "%s-%s-%s" % [date.substr(0,4), date.substr(4,2), date.substr(6,2)]

				var start_time = ""
				var end_time = ""
				if dtstart.length() >= 15:
					start_time = "%s:%s" % [dtstart.substr(9,2), dtstart.substr(11,2)]
				if dtend.length() >= 15:
					end_time = "%s:%s" % [dtend.substr(9,2), dtend.substr(11,2)]

				current_event["start"] = start_time
				current_event["end"] = end_time
				current_event["date"] = date_formatted

				# Dodaj do listy
				if not data.has(date_formatted):
					data[date_formatted] = {}

				var uid = current_event.get("UID", "UNKNOWN")
				data[date_formatted][uid] = current_event.duplicate()
			continue

		if not in_event or line == "":
			continue

		# Parsowanie linii klucz:wartość
		var parts = line.split(":", false, 2)
		if parts.size() < 2:
			continue

		var key = parts[0].strip_edges()
		var value = parts[1].strip_edges()

		# Specjalne przetwarzanie SUMMARY
		if key == "SUMMARY":
			var summary: String = line.replace("SUMMARY:","")

			# 1. Wyciągnij nauczyciela po dwukropku (: ...)
			if summary.find(":") != -1:
				var parts2 = summary.split(":", false, 2)
				if parts2.size() >= 2:
					current_event["teacher"] = parts2[1].strip_edges().split("(")[0]
				else:
					current_event["teacher"] = "Brak danych"
			else:
				current_event["teacher"] = "Brak danych"

			# 2. Wyciągnij podgrupę (PG: X)
			if summary.find("(PG:") != -1:
				var part = summary.split("(PG: ")[1]
				current_event["subgroup"] = part.split(")")[0]
				summary = summary.replace("(PG: " + current_event["subgroup"] + ")", "")
			else:
				current_event["subgroup"] = "O"

			# 3. Zapisz końcową nazwę zajęć
			current_event["SUMMARY"] = summary.strip_edges()

		else:
			current_event[key] = value
	var parsed_lessons:Array[Day] = []
	for e in data.keys():
		var o: Day = Day.new(e,data[e])
		parsed_lessons.append(o)
	list_of_lessons = parsed_lessons
	state = "Acquired lessons.."
	lessons_update.emit()
