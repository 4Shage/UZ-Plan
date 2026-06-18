class_name DayScene extends Control
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

const LESSON_SCENE: PackedScene = preload("res://scenes/Lesson.tscn")
const CURRENT_DAY = preload("res://scenes/CurrentDay.tscn")

@export var day:String
@export var id:int


func _ready() -> void:
	self.name = day
	var cDay = CURRENT_DAY.instantiate()
	cDay.day = day
	v_box_container.add_child(cDay)
	for lesson:String in Master.list_of_lessons[id].lessons:
		var child:LessonScene = LESSON_SCENE.instantiate()
		child.dayID = id
		child.lesson = Master.list_of_lessons[id].lessons[lesson]
		v_box_container.add_child(child)
