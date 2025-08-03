extends Control

@onready var main_pn = find_child("MainPn")
@onready var progress_bar = find_child("ProgressBar")
var step
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	step = progress_bar.size.x / 100  # 100 level
	
	for c in progress_bar.get_children():
		c.queue_free()
	for l in g.v.game_server_config.level_rewards:
		var n = reward_level_node_scene.instantiate()
		progress_bar.add_child(n)
		n.position = Vector2(step * l.level, 0)
		n.set_info(l)
		
	var cur_exp = g.v.player_info_mgr.my_user_data.exp
	var max_exp = g.v.game_server_config.total_all_exp()
	var p = cur_exp * 1.0 / max_exp * 100
	print("Debugg", cur_exp," ", max_exp," ", p)
	progress_bar.value = 1
	
	var level = g.v.game_server_config.convert_exp_to_level(g.v.player_info_mgr.my_user_data.exp)
	if g.v.game_server_config.is_max_level(level):
		progress_bar.value = 100
	else:
		var a = g.v.game_server_config.exp_levels[level - 1]
		var b = g.v.game_server_config.exp_levels[level]
		var cur = g.v.player_info_mgr.my_user_data.exp - a
		var des = b - a
		progress_bar.value = cur * 1.0 / des + level

var reward_level_node_scene = preload("res://scenes/level/LevelNode.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.queue_free()
