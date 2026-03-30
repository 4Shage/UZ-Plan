class_name DayScene extends Control
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

const LESSON_SCENE: PackedScene = preload("res://scenes/Lesson.tscn")

@export var day:String


func _ready() -> void:
	self.name = day
	for lesson in Master.list_of_lessons[day]:
		var child:LessonScene = LESSON_SCENE.instantiate()
		child.day = day
		child.uid = lesson
		v_box_container.add_child(child)
