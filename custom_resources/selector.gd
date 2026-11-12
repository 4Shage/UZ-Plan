extends Button
class_name Selector

@export var ID: String
var data: Dictionary[String, String]
signal result(res:String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_button_pressed)
	add_to_group("select")


func _button_pressed():
	print("Test1")
	get_tree().call_group("Selectors","begin",ID, data)
	for selector in get_tree().get_nodes_in_group("Selectors"):
		selector.show()

func ret(aw: String,res:String) -> void:
	if ID != aw: return
	result.emit(res)
