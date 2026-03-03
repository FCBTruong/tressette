extends Node

@onready var main_pn = find_child("MainPn")

# Called when the node enters the scene tree for the first time.
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
	
func _link_now():
	self._on_close()
	g.v.player_info_mgr.is_linking_acc = true
	g.v.player_info_mgr.uid_linking = g.v.player_info_mgr.get_user_id()
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOG_OUT, [])
	pass
