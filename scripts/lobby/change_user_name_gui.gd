extends Node

@onready var input_name = find_child("LineEdit")
@onready var main_pn = find_child("MainPn")

func _ready() -> void:

	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_close():
	self.queue_free()
	
func _click_ok():
	var new_name = input_name.text
	if new_name == '':
		return
	self.queue_free()
		
	print("new name...", new_name)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.ChangeUserName.new()
	pkg.set_name(new_name)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHANGE_USER_NAME, pkg.to_bytes())
	
	g.v.player_info_mgr.my_user_data.name = new_name
	pass
