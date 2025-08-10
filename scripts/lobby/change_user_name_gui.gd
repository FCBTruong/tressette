extends Node

@onready var input_name = find_child("LineEdit")
@onready var main_pn = find_child("MainPn")
@onready var rename_card_lb = find_child("RenameCardLb")

func _ready() -> void:

	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	rename_card_lb.text = str(g.v.player_info_mgr.price_change_name)

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_close():
	self.queue_free()
	
func _click_ok():
	var new_name = input_name.text.strip_edges()

	# empty check
	if new_name.is_empty():
		return

	# length check (3–20 characters)
	if new_name.length() < 3 or new_name.length() > 25:
		g.v.scene_manager.show_toast(tr("INVALID_USER_NAME"))
		return

	# optional regex check — only letters, numbers, underscores
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_ ]+$")  # change pattern to fit your rules
	if not regex.search(new_name):
		g.v.scene_manager.show_toast(tr("INVALID_USER_NAME"))
		return
		
	if g.v.inventory_mgr.get_rename_card_number() < g.v.player_info_mgr.price_change_name:
		g.v.scene_manager.show_toast(tr("NOT_ENOUGH_RENAME_CARD"))
		return

	# passed checks → close UI
	self.queue_free()

		
	print("new name...", new_name)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.ChangeUserName.new()
	pkg.set_name(new_name)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHANGE_USER_NAME, pkg.to_bytes())
	
	g.v.player_info_mgr.my_user_data.name = new_name
	g.v.signal_bus.emit_signal_global('on_changed_username')
	pass
