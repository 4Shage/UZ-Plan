class_name LessonScene
extends Control

@onready var panel_container: PanelContainer = $PanelContainer
@onready var summary: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SUMMARY
@onready var categories: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CATEGORIES
@onready var start: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/start
@onready var end: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/end
@onready var subgroup: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/subgroup
@onready var teacher: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/teacher
@onready var location: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/LOCATION

var lesson: Lesson


func _ready() -> void:
	summary.text = lesson.summary
	categories.text = lesson.category_key()
	start.text = lesson.start_time
	end.text = lesson.end_time
	teacher.text = lesson.teacher
	location.text = lesson.location
	subgroup.text = "PG " + ", ".join(lesson.subgroups)
	subgroup.visible = not lesson.subgroups.is_empty()
	panel_container.theme_type_variation = "PanelContainer" + categories.text
