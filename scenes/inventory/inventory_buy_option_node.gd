extends Control

@onready var lb = find_child("Label")
@onready var checkbox: CheckBox = find_child("Checkbox")
var info
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_info(s):
	info = s
	lb.text = str(s['duration']) + " " + tr("DAYS")


func _on_checkbox_pressed() -> void:
	g.v.scene_manager.inventory_gui.click_check_buy_option(self)
	pass # Replace with function body.

func on_selected():
	self.checkbox.button_pressed = true

func de_selected():
	self.checkbox.button_pressed = false
	pass
	
func get_price():
	return info['price']
