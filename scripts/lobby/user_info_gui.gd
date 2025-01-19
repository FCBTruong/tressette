extends CanvasLayer

# Close button action
func _on_CloseButton_pressed():
	hide()

# Show popup at the center of the screen
func _show_popup():
	show()

@onready var user_name_lb = find_child('UserNameLb')
@onready var gold_lb = find_child('GoldLb')
func _ready() -> void:
	user_name_lb.text = PlayerInfoMgr.my_user_data.name
	gold_lb.text = StringUtils.point_number(PlayerInfoMgr.my_user_data.gold)
