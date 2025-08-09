extends Node


@onready var main_pn = find_child("MainPn")
@onready var title_lb = find_child("TitleLb")
@onready var gold_lb = find_child("GoldLb")

var reward_node_scene = preload("res://scenes/lobby/RewardNode.tscn")
@onready var list_pn = find_child("HBoxContainer")
func _ready() -> void:

	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	
func set_info(title, rewards: Array[Reward] = []):
	self.title_lb.text = title
	
	NodeUtils.remove_all_child(list_pn)
	for r in rewards:
		var n = reward_node_scene.instantiate()
		list_pn.add_child(n)
		n.set_info(r)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _click_ok():
	self.queue_free()
	pass
