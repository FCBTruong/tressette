extends Node


@onready var ads_icon = find_child("AdsIcon")
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
	
	var t = create_tween()
	t.set_loops()
	t.tween_property(
		ads_icon,
		"scale",
		Vector2(1, 1),
		0.5
	)
	t.tween_property(
		ads_icon,
		"scale",
		Vector2(0.9, 0.9),
		0.5
	)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_close():
	self.queue_free()
	pass
	
func _watch_ads():
	self.queue_free()
	g.admob_mgr._on_reward_pressed()
	pass
