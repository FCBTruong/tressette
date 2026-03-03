extends Node

@onready var input_name: LineEdit = find_child("LineEdit")
@onready var main_pn = find_child("MainPn")
func _ready() -> void:

	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
var match_id
var is_join
func set_info(_match_id, _is_join = true):
	self.match_id = _match_id
	self.is_join = _is_join


func _on_close():
	self.queue_free()
	
func _click_ok():
	var new_name = input_name.text.strip_edges()

	# empty check
	if new_name.is_empty():
		return

	if self.match_id != int(new_name):
		g.v.scene_manager.show_toast("WRONG_PASSWORD")
		return
		
	if is_join:
		g.v.game_manager.join_game_by_id(match_id)
	else:
		g.v.game_manager.view_game_by_id(match_id)
	# passed checks → close UI
	self.queue_free()

		
	
