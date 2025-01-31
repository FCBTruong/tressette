extends CanvasLayer

# Close button action
func _on_CloseButton_pressed():
	hide()

# Show popup at the center of the screen
func _show_popup():
	show()

@onready var user_name_lb = find_child('UserNameLb')
@onready var gold_lb = find_child('GoldLb')
@onready var main_pn = find_child('MainPn')
@onready var uid_lb = find_child('UidLb')
func _ready() -> void:
	user_name_lb.text = PlayerInfoMgr.my_user_data.name
	gold_lb.text = StringUtils.point_number(PlayerInfoMgr.my_user_data.gold)
	uid_lb.text = str(PlayerInfoMgr.my_user_data.uid)
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0.5
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.4)
	
	
func _copy_uid() -> void:
	DisplayServer.clipboard_set(str(PlayerInfoMgr.my_user_data.uid))
	pass
