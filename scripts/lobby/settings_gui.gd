extends CanvasLayer

var default_pos: Vector2

func _ready() -> void:
	default_pos = $Panel.position
	
	# Shift X so we can tween back to default at startup
	$Panel.position.x += 300
	
	var tween = create_tween()
	tween.tween_property(
		$Panel,
		"position",
		default_pos,
		0.3
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _hide_gui() -> void:
	var tween = create_tween()
	tween.tween_property(
		$Panel,
		"position",
		default_pos + Vector2(300, 0),
		0.3
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	# This is the correct way in Godot 4 to connect the `finished` signal
	tween.finished.connect(_on_close_tween_finished)

func _on_close_tween_finished() -> void:
	hide()
	$Panel.position = default_pos

func _logout() -> void:
	SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
