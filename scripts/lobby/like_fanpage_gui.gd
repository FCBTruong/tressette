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
	
	var n = g.v.storage_cache.fetch("show_fanpage", 0)
	g.v.storage_cache.store("show_fanpage", (n + 1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func on_close():
	self.queue_free()
	
func like_fanpage():
	self.queue_free()
	g.v.storage_cache.store("show_fanpage", g.v.game_constants.MAX_SHOW_FANPAGE_LIKE)
	OS.shell_open("https://www.facebook.com/profile.php?id=61573779305884")
