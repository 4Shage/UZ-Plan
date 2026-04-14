class_name DayScene extends Control
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

const LESSON_SCENE: PackedScene = preload("res://scenes/Lesson.tscn")

@export var day:String
@export var id:int


func _ready() -> void:
	self.name = day
	for lesson:String in Master.list_of_lessons[id].lessons:
		var child:LessonScene = LESSON_SCENE.instantiate()
		child.dayID = id
		child.lesson = Master.list_of_lessons[id].lessons[lesson]
		v_box_container.add_child(child)
