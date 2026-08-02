extends PanelContainer
@onready var label: Label = $VBoxContainer/Label
@onready var item_list: ItemList = $VBoxContainer/ItemList

var data: Dictionary[String, String]

func populate() -> void:
	item_list.clear()
	for i in data:
		item_list.add_item(data[i])

func begin(lname:String, ndata: Dictionary[String, String]) -> void:
	self.data = ndata
	print("Test")
	label.text = lname
	populate()
	self.show()


func _on_button_pressed() -> void:
	self.hide()
	var res: String
	for i in item_list.get_selected_items():
		res = data.find_key(item_list.get_item_text(i))
	get_tree().call_group("select","ret",label.text, res)
