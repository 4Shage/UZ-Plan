extends Control

const SWIPE_DISTANCE := 100.0
const STATUS_SECONDS := 3.0

@onready var course_button: Button = %CourseButton
@onready var group_button: Button = %GroupButton
@onready var refresh_button: Button = %RefreshButton
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var today_button: Button = %TodayButton
@onready var date_label: Label = %DateLabel
@onready var status: Label = %Status
@onready var day_view: DayScene = %DayView
@onready var picker: ListPicker = $Selector
@onready var day_nav: Control = %DayNav
@onready var tabs: TabContainer = %Tabs
@onready var margin: MarginContainer = %Margin

var _days: Array[Day] = []
var _index := 0
var _swipe_start := Vector2.ZERO


func _ready() -> void:
	get_tree().root.content_scale_factor = 2.0 if OS.has_feature("mobile") else 1.0
	status.hide()
	_apply_safe_area()
	get_tree().root.size_changed.connect(_apply_safe_area)

	course_button.pressed.connect(_pick_course)
	group_button.pressed.connect(_pick_group)
	refresh_button.pressed.connect(Master.refresh)
	previous_button.pressed.connect(_step.bind(-1))
	next_button.pressed.connect(_step.bind(1))
	today_button.pressed.connect(func() -> void: _show_day(_default_index()))

	Master.lessons_update.connect(_reload)
	Master.subgroups_update.connect(_reload)
	Master.groups_update.connect(_update_buttons)
	Master.courses_update.connect(_update_buttons)
	Master.state_changed.connect(_show_status)
	Master.busy_changed.connect(func(busy: bool) -> void: refresh_button.disabled = busy)

	await Master.start()
	if Master.group_id.is_empty():
		tabs.current_tab = 1
		_pick_course()


func _input(event: InputEvent) -> void:
	if picker.visible or tabs.current_tab != 0:
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_swipe_start = event.position
		else:
			_finish_swipe(event.position - _swipe_start)
	elif event.is_action_pressed("a") or event.is_action_pressed("ui_left"):
		_step(-1)
	elif event.is_action_pressed("d") or event.is_action_pressed("ui_right"):
		_step(1)


func _pick_course() -> void:
	if Master.list_of_courses.is_empty():
		_show_status("Course list unavailable - check connection")
		return
	var id := await picker.pick("Course", Master.list_of_courses, Master.course_id)
	if id.is_empty():
		return
	if id != Master.course_id:
		await Master.select_course(id)
	elif not Master.group_id.is_empty():
		return
	_pick_group()


func _pick_group() -> void:
	if Master.list_of_groups.is_empty():
		_show_status("Pick a course first" if Master.course_id.is_empty() else "Group list unavailable - check connection")
		return
	var id := await picker.pick("Group", Master.list_of_groups, Master.group_id)
	if id.is_empty():
		return
	tabs.current_tab = 0
	if id != Master.group_id:
		await Master.select_group(id)


func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	var ui_scale := get_tree().root.content_scale_factor
	margin.add_theme_constant_override("margin_left", 4 + int(safe.position.x / ui_scale))
	margin.add_theme_constant_override("margin_top", 4 + int(safe.position.y / ui_scale))
	margin.add_theme_constant_override("margin_right", 4 + int((window.x - safe.end.x) / ui_scale))
	margin.add_theme_constant_override("margin_bottom", 4 + int((window.y - safe.end.y) / ui_scale))


func _update_buttons() -> void:
	course_button.text = Master.course_name() if not Master.course_name().is_empty() else "Course"
	group_button.text = Master.group_name() if not Master.group_name().is_empty() else "Group"


func _reload() -> void:
	_update_buttons()
	var previous := _days[_index].date if _index < _days.size() else ""
	_days = Master.days()
	day_nav.visible = not _days.is_empty()
	if _days.is_empty():
		day_view.show_message("Pick a course and group to see your plan" if Master.group_id.is_empty() else "No lessons found")
		return
	var kept := _days.find_custom(func(day: Day) -> bool: return day.date == previous)
	_show_day(kept if kept >= 0 else _default_index())


func _show_day(index: int) -> void:
	_index = clampi(index, 0, _days.size() - 1)
	var day := _days[_index]
	date_label.text = "%s, %s" % [day.weekday(), day.pretty()]
	previous_button.disabled = _index == 0
	next_button.disabled = _index == _days.size() - 1
	today_button.disabled = day.date == Day.today()
	day_view.show_day(day)


func _default_index() -> int:
	var today := Day.today()
	for i in _days.size():
		if _days[i].date >= today:
			return i
	return _days.size() - 1


func _step(direction: int) -> void:
	if not _days.is_empty():
		_show_day(_index + direction)


func _finish_swipe(delta: Vector2) -> void:
	if absf(delta.x) < SWIPE_DISTANCE or absf(delta.x) < absf(delta.y) * 1.5:
		return
	_step(-1 if delta.x > 0 else 1)


func _show_status(text: String) -> void:
	status.text = text
	status.show()
	await get_tree().create_timer(STATUS_SECONDS).timeout
	if status.text == text:
		status.hide()
