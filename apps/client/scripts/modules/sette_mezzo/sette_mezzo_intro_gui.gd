extends Node

@onready var main_pn = find_child("Main")
var info
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sette_times = g.v.storage_cache.fetch("sette_mezzo_play", 0)
	g.v.storage_cache.store("sette_mezzo_play", (sette_times + 1))
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	


func on_close():
	self.queue_free()
	
func click_play():
	g.v.sette_mezzo_mgr.quick_play()
	self.on_close()
	pass
