extends Node

@onready var main_pn = find_child('MainPn')
@onready var close_btn = find_child("CloseBtn")
@onready var next_btn = find_child("NextBtn")
@onready var previous_btn = find_child("PreviousBtn")
var tween
func _ready() -> void:
	tween = create_tween()
	var default_pos = main_pn.position
	#main_pn.modulate.a = 0
	main_pn.position.y -= 600
	
	previous_btn.visible = false

	
	tween.parallel().tween_property(main_pn, 'position', default_pos, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1, 1), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)  
	tween.tween_property(next_btn, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1, 1), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_close() -> void:
	if tween and tween.is_running():
		tween.kill()
	self.queue_free()
	
func _click_next_page():
	previous_btn.visible = true
	next_btn.visible = false
	
	main_pn.texture = load('res://assets/images/lobby/guide/guide_content2.png')
	pass

func _click_previous_page():
	next_btn.visible = true
	previous_btn.visible = false
	main_pn.texture = load('res://assets/images/lobby/guide/guide_content.png')
	pass
