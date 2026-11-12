class_name DayScene
extends Control

const LESSON_SCENE: PackedScene = preload("res://scenes/Lesson.tscn")
const LONG_BREAK_MINUTES := 45
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
	column.add_child(_summary(day))
	var gaps := day.gaps()
	for i in day.lessons.size():
		if gaps[i] > 0:
			column.add_child(_break_row(gaps[i]))
		var lesson := day.lessons[i]
		var card: LessonScene = LESSON_SCENE.instantiate()
		card.lesson = lesson
		column.add_child(card)


func show_message(text: String) -> void:
	_clear()
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(10, 160)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(label)


func _summary(day: Day) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"SummaryPanel"
	var row := HBoxContainer.new()
	panel.add_child(row)
	var breaks := Day.format_minutes(day.total_break()) if day.total_break() > 0 else "-"
	row.add_child(_stat("Start", day.start_time()))
	row.add_child(_stat("End", day.end_time()))
	row.add_child(_stat("Breaks", breaks))
	return panel


func _stat(caption: String, value: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_child(_label(caption, &"Muted"))
	box.add_child(_label(value, &"Value"))
	return box


func _break_row(minutes: int) -> PanelContainer:
	var long := minutes >= LONG_BREAK_MINUTES
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"LongBreakPanel" if long else &"BreakPanel"
	var text := "%s  -  %s" % ["Long break" if long else "Break", Day.format_minutes(minutes)]
	panel.add_child(_label(text, &"LongBreakText" if long else &"BreakText"))
	return panel


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _clear() -> void:
	scroll.scroll_vertical = 0
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
