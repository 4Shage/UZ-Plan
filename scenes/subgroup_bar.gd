extends HFlowContainer


func _ready() -> void:
	Master.lessons_update.connect(rebuild)
	Master.subgroups_update.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var labels := Master.available_subgroups()
	get_parent().visible = not labels.is_empty()
	if labels.is_empty():
		return
	add_child(_chip("All", Master.subgroups.is_empty(), Master.clear_subgroups))
	for label: String in labels:
		add_child(_chip("PG " + label, label in Master.subgroups, Master.toggle_subgroup.bind(label)))


func _chip(text: String, pressed: bool, action: Callable) -> Button:
	var chip := Button.new()
	chip.text = text
	chip.toggle_mode = true
	chip.button_pressed = pressed
	chip.theme_type_variation = &"Chip"
	chip.custom_minimum_size = Vector2(56, 44)
	chip.pressed.connect(action)
	return chip
