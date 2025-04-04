extends Node

@onready var main_pn = find_child("MainPn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NodeUtils.set_center_pivot(main_pn)
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	var n = g.v.storage_cache.fetch("join_group_fb", 0)
	g.v.storage_cache.store("join_group_fb", (n + 1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func on_close():
	self.queue_free()
	
func join_group_fb():
	self.queue_free()
	g.v.storage_cache.store("join_group_fb", g.v.game_constants.MAX_SHOW_JOIN_GROUP_FB)
	OS.shell_open("https://www.facebook.com/share/g/1ALgWc7Lg9/")
