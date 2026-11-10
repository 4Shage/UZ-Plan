class_name ListPicker
extends PanelContainer

signal chosen(id: String)

const FOLD := {"ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n", "ó": "o", "ś": "s", "ź": "z", "ż": "z"}
const CURRENT_COLOR := Color(0.2, 0.4, 0.8)

@onready var title_label: Label = %Title
@onready var search: LineEdit = %Search
@onready var scroll: ScrollContainer = %Scroll
@onready var rows: VBoxContainer = %Rows
@onready var empty_label: Label = %Empty

var _items := {}
var _buttons := {}


static func fold(text: String) -> String:
	var result := text.to_lower()
	for letter: String in FOLD:
		result = result.replace(letter, FOLD[letter])
	return result


func _ready() -> void:
	search.text_changed.connect(_filter)
	%CloseButton.pressed.connect(_finish.bind(""))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		_finish("")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_finish("")
		get_viewport().set_input_as_handled()


func pick(title: String, items: Dictionary, current: String) -> String:
	if visible:
		_finish("")
	title_label.text = title
	_items = items
	search.text = ""
	_build(current)
	show()
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		search.grab_focus()
	_scroll_to(current)
	var id: String = await chosen
	hide()
	return id


func _build(current: String) -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	_buttons.clear()
	empty_label.hide()
	for id: String in _items:
		var button := Button.new()
		button.text = _items[id]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 44
		if id == current:
			var style := StyleBoxFlat.new()
			style.bg_color = CURRENT_COLOR
			style.set_corner_radius_all(4)
			button.add_theme_stylebox_override("normal", style)
		button.pressed.connect(_finish.bind(id))
		rows.add_child(button)
		_buttons[id] = button


func _filter(query: String) -> void:
	var terms := fold(query).split(" ", false)
	var any_visible := false
	for id: String in _buttons:
		var matched := _matches(fold(_items[id]), terms)
		_buttons[id].visible = matched
		any_visible = any_visible or matched
	empty_label.visible = not any_visible
	scroll.scroll_vertical = 0


func _matches(haystack: String, terms: PackedStringArray) -> bool:
	for term in terms:
		if not haystack.contains(term):
			return false
	return true


func _scroll_to(id: String) -> void:
	if not _buttons.has(id):
		return
	await get_tree().process_frame
	scroll.ensure_control_visible(_buttons[id])


func _finish(id: String) -> void:
	chosen.emit(id)
