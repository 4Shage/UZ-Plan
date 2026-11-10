class_name DayScene
extends Control

const LESSON_SCENE: PackedScene = preload("res://scenes/Lesson.tscn")
const CURRENT_DAY: PackedScene = preload("res://scenes/CurrentDay.tscn")
const KEY_SCROLL_STEP := 90

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var column: VBoxContainer = $ScrollContainer/VBoxContainer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("w", true):
		scroll.scroll_vertical -= KEY_SCROLL_STEP
	elif event.is_action_pressed("s", true):
		scroll.scroll_vertical += KEY_SCROLL_STEP


func show_day(day: Day) -> void:
	_clear()
	var header: Control = CURRENT_DAY.instantiate()
	header.day = day.date
	column.add_child(header)
	for lesson in day.lessons:
		var card: LessonScene = LESSON_SCENE.instantiate()
		card.lesson = lesson
		column.add_child(card)


func show_message(text: String) -> void:
	_clear()
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 160
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(label)


func _clear() -> void:
	scroll.scroll_vertical = 0
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
