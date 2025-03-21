extends Node

@onready var main_pn = find_child("MainPn")
@onready var mission_list_pn = find_child("MissionList")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NodeUtils.set_center_pivot(main_pn)
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	for c in mission_list_pn.get_children():
		c.queue_free()
		
	var mission_node_scene = load("res://scenes/mission/MissionNode.tscn")
	for m in g.v.mission_mgr.missions:
		var n  = mission_node_scene.instantiate()
		mission_list_pn.add_child(n)
		n.set_mission_info(m)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close():
	self.queue_free()
