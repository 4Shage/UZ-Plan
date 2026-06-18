extends PanelContainer
@onready var label: Label = $VBoxContainer/Label
@onready var item_list: ItemList = $VBoxContainer/ItemList

func populate(data: Array[String]) -> void:
	item_list.clear()
	for i in data:
		item_list.add_item(i)

func begin(lname:String, data:Array[String]) -> void:
	print("Test")
	label.text = lname
	populate(data)
	self.show()


func _on_button_pressed() -> void:
	self.hide()
	var res: String
	for i in item_list.get_selected_items():
		res = item_list.get_item_text(i)
	get_tree().call_group("select","ret",label.text, res)
