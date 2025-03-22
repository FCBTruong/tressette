extends Node


# Called when the node enters the scene tree for the first time.
var is_showing = false
@onready var main = find_child('Panel')
@onready var content_pn = find_child("VBoxContainer")
@onready var emo_group_node = find_child("EmoGroupNode")
var default_pos
var tween
var did_setup = false
func _ready() -> void:
	default_pos = main.position
	main.visible = false
	pass # Replace with function body.

func setup_emo_list():
	if did_setup:
		return
		
	did_setup = true
	for i in range(4):
		var x = emo_group_node.duplicate()
		content_pn.add_child(x)
	var emo_id = 1
	for c in content_pn.get_children():
		for e in c.get_children():
			e.set_emo(emo_id, self)
			emo_id += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	
func hide_emo():
	is_showing = false
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		main,
		'position',
		Vector2(
			default_pos.x,
			default_pos.y + 500
		),
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	tween.tween_callback(
		func():
			main.visible = false
	)
func show_emo():
	setup_emo_list()
	main.visible = true
	main.position.y = default_pos.y + 200
	is_showing = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(
		main,
		'position',
		Vector2(
			default_pos.x,
			default_pos.y
		),
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_emo_btn_pressed() -> void:
	if is_showing:
		hide_emo()
	else:
		show_emo()
	pass # Replace with function body.
