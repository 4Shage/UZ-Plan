class_name LessonScene extends Control
@onready var panel_container: PanelContainer = $PanelContainer

@onready var summary: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SUMMARY
@onready var categories: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CATEGORIES
@onready var start: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/start
@onready var end: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/end
@onready var subgroup: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/subgroup
@onready var teacher: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/teacher
@onready var location: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/LOCATION

@export var dayID:int
@export var uid:String
@export var lesson:Lesson
func _init() -> void:
	Master.subgroups_update.connect(subgroup_hide)
func subgroup_hide() -> void:
	if lesson == null:
		self.queue_free()
		return
	if lesson.subgroup != Master.subgroup_id and lesson.subgroup != "O":
		self.hide()
	else: self.show()

func _ready() -> void:
	if lesson == null:
		self.queue_free()
		return

	self.name = lesson.uid
	subgroup_hide()
	
	# Wypełnianie pól
	summary.text = lesson.summary.split(":")[0]
	categories.text = "C" if lesson.categories=="Ć" else lesson.categories
	start.text = lesson.start_time
	end.text = lesson.end_time
	subgroup.text = lesson.subgroup
	if subgroup.text == "O": subgroup.hide()
	teacher.text = lesson.teacher
	location.text = lesson.location
	panel_container.theme_type_variation = "PanelContainer"+categories.text
