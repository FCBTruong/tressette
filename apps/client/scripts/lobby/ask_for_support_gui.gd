extends Node

@onready var input_name = find_child("LineEdit")
@onready var main_pn = find_child("MainPn")

func _ready() -> void:
	g.v.storage_cache.store("show_ask_support", '1')
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
	_on_close()
	g.v.popup_mgr.add_popup_intermediate("res://scenes/lobby/FirstBuyGUI.tscn")
	pass
