extends Node

@onready var main_pn = find_child("MainPn")
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)


@onready var check_confirm = find_child("CheckConfirm")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.queue_free()
	
func _delete_account():
	if not check_confirm.is_pressed():
		g.v.scene_manager.show_toast("PLEASE_CONFIRM_DELETE")
		return
	g.v.game_manager.request_delete_account()
	g.v.scene_manager.add_loading(5)
