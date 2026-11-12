class_name LessonScene
extends PanelContainer

const CATEGORIES := ["W", "C", "L", "P", "S", "E", "R", "K"]

@onready var time: Label = %Time
@onready var subgroup: Label = %Subgroup
@onready var badge: PanelContainer = %BadgePanel
@onready var category: Label = %Category
@onready var summary: Label = %Summary
@onready var teacher: Label = %Teacher
@onready var location: Label = %Location

var lesson: Lesson


func _ready() -> void:
	var key := lesson.category_key()
	var suffix := key if key in CATEGORIES else ""
	theme_type_variation = "Lesson" + suffix
	badge.theme_type_variation = "Badge" + suffix
	badge.visible = not key.is_empty()
	time.text = "%s - %s" % [lesson.start_time, lesson.end_time]
	subgroup.text = "PG " + ", ".join(lesson.subgroups)
	subgroup.visible = not lesson.subgroups.is_empty()
	category.text = key
	summary.text = lesson.summary
	teacher.text = lesson.teacher
	location.text = lesson.location
