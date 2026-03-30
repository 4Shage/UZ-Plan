class_name LessonScene extends Control
@onready var panel_container: PanelContainer = $PanelContainer

@onready var summary: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SUMMARY
@onready var categories: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CATEGORIES
@onready var start: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/start
@onready var end: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/end
@onready var subgroup: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/subgroup
@onready var teacher: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/teacher
@onready var location: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/LOCATION

@export var day:String
@export var uid:String
func _init() -> void:
	Master.subgroups_update.connect(subgroup_hide)
func subgroup_hide() -> void:
	var c_lesson: Dictionary = Master.list_of_lessons[day].get(uid, {})
	if c_lesson.is_empty():
		push_error("Nie znaleziono lekcji UID: %s" % uid)
		self.queue_free()
	if c_lesson["subgroup"] != Master.subgroup_id and c_lesson["subgroup"] != "O":
		self.hide()
	else: self.show()

func _ready() -> void:
	self.name = uid
	subgroup_hide()
	if not Master.list_of_lessons.has(day):
		push_error("Nie znaleziono dnia: %s" % day)
		self.queue_free()

	var c_lesson: Dictionary = Master.list_of_lessons[day].get(uid, {})

	if c_lesson.is_empty():
		push_error("Nie znaleziono lekcji UID: %s" % uid)
		self.queue_free()
	
	# Wypełnianie pól
	summary.text = c_lesson.get("SUMMARY", "Brak danych")
	summary.text = summary.text.split(":")[0]
	categories.text = c_lesson.get("CATEGORIES", "-")
	start.text = c_lesson.get("start", "")
	end.text = c_lesson.get("end", "")
	subgroup.text = c_lesson.get("subgroup", "O")
	if subgroup.text == "O": subgroup.hide()
	teacher.text = c_lesson.get("teacher", "Brak danych")
	location.text = c_lesson.get("LOCATION", "—")
	var sbf := StyleBoxFlat.new()
	match categories.text:
		"W": sbf.bg_color = Color(0.2, 0.5, 1.0)  # 🔵 Wykład – niebieski
		"Ć": sbf.bg_color = Color(0.2, 0.8, 0.3)  # 🟢 Ćwiczenia – zielony
		"L": sbf.bg_color = Color(1.0, 0.6, 0.2)  # 🟠 Laboratorium – pomarańczowy
		"P": sbf.bg_color = Color(0.25, 0.80, 0.35) # 🟢 Projekt - zielony
		"S": sbf.bg_color = Color(0.80, 0.45, 0.85) # 🟣 Seminarium - fioletowy
		"K": sbf.bg_color = Color(0.55, 0.55, 0.55) # ⚫ Konsultacje - szary
		"E": sbf.bg_color = Color(1.00, 0.35, 0.35) # 🔴 Egzamin - czerwony
		"Z": sbf.bg_color = Color(1.00, 0.55, 0.10) # 🟧 Zaliczenie - ciemny pomarańcz
		"R": sbf.bg_color = Color(0.40, 0.75, 0.90) # 🔵 Rezerwacja - jasnoniebieski
		_: sbf.bg_color = Color(0.3, 0.3, 0.3)       # ❔ Nieznany typ - szary

	# Opcjonalnie: zaokrąglenia i efekt wizualny
	sbf.shadow_color = Color(0, 0, 0, 0.2)
	sbf.shadow_size = 3

	panel_container.add_theme_stylebox_override("panel", sbf)
