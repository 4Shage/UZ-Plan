extends Node
signal internet
signal state_changed(text:String)
signal courses_update
signal groups_update
signal subgroups_update
signal lessons_update

const LIST_OF_COURSES:String = "https://plan.uz.zgora.pl/grupy_lista_kierunkow.php"


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
var list_of_lessons:Dictionary:
	set(value):
		Settings.static_set("plan","lessons",value)
		list_of_lessons = value
		lessons_update.emit()
var list_of_lessonsv2:Array[Day]
var course_id: int:
	set(value):
		get_course_groups()
		course_id = value
		Settings.static_set("plan","course_id",course_id)
var group_id:int:
	set(value):
		get_lessons()
		group_id = value
		Settings.static_set("plan","group_id",group_id)
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
	http.request("https://www.google.com")

func download(link:String,ext:String,override_name:String = "") -> String:
	var http := prepare_http()
	var file_name:String = "user://"+((link.get_slice("/",link.get_slice_count("/")-1) + "." + ext) if override_name.is_empty() else (override_name + "." + ext))
	http.download_file = file_name
	self.add_child(http)
	http.request(link,[],HTTPClient.METHOD_GET,"")
	var a:Array = await http.request_completed
	#while a[1] != 200:
		#http.request(link,[],HTTPClient.METHOD_GET,"")
		#a = await http.request_completed
		#print(a[1])
	print(a[1])
	http.queue_free()
	if !FileAccess.file_exists(file_name):
		print("Using defaults")
		var default_file:String = file_name.replace("user://","res://default_assets/")
		if !FileAccess.file_exists(default_file):
			return default_file
	else:
		print(file_name+" was downloaded!")
	return file_name

func start() -> void:
	check_net()
	await internet
	state = "Checking plan..."
	var file := FileAccess.open(await download(LIST_OF_COURSES,"html"), FileAccess.READ)
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
	if Settings.static_get("plan","course_id") != null:
		course_id = Settings.static_get("plan","course_id")
		get_course_groups()
	if Settings.static_get("plan","group_id") != null:
		group_id = Settings.static_get("plan","group_id")
		get_lessons()
	if Settings.static_get("plan","subgroup_id") != null:
		subgroup_id = Settings.static_get("plan","subgroup_id")
		subgroups_update.emit()


func get_course_groups() -> void:
	if course_id == null: return
	state = "Getting courses..."
	list_of_groups.clear()
	var regex = RegEx.new()
	var course_file := FileAccess.open(await download("https://plan.uz.zgora.pl/grupy_lista_grup_kierunku.php?ID="+str(course_id),"html","groups"),FileAccess.READ)
	regex.compile(r'grupy_plan\.php\?ID=(\d+)">([^<]+)</a>')
	for m in regex.search_all(course_file.get_as_text()):
		list_of_groups[m.get_string(1)] = m.get_string(2).strip_edges()
	groups_update.emit()

func get_lessons() -> void:
	if group_id == null:
		return
	state = "Getting lessons..."
	list_of_lessons.clear()
	var url = "https://plan.uz.zgora.pl/grupy_ics.php?ID={0}&KIND=GG".format([group_id])
	var group_file := FileAccess.open(await download(url, "ics", "plan"), FileAccess.READ)
	if not group_file:
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
				if not list_of_lessons.has(date_formatted):
					list_of_lessons[date_formatted] = {}

				var uid = current_event.get("UID", "UNKNOWN")
				list_of_lessons[date_formatted][uid] = current_event.duplicate()
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
	list_of_lessonsv2.clear()
	for e in list_of_lessons.keys():
		var o: Day = Day.new(e,list_of_lessons[e])
		list_of_lessonsv2.append(o)
	state = "Acquired lessons.."
	lessons_update.emit()
