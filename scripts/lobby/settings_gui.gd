extends CanvasLayer

var default_pos: Vector2

@onready var classic_card = find_child('ClassicCardBtn')
@onready var modern_card = find_child('ModernCardBtn')
@onready var check_icon_class = classic_card.find_child('CheckIcon')
@onready var check_icon_modern = modern_card.find_child('CheckIcon')
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
	_update_choosing_card()

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
	GameClient.send_packet(GameConstants.CMDs.LOG_OUT, [])
	
func _choose_card_classic():
	GameManager.change_card_style(0)
	_update_choosing_card()
	
func _choose_card_modern():
	GameManager.change_card_style(1)
	_update_choosing_card()
	
func _update_choosing_card():
	var p = null
	if GameManager.card_style == 0:
		check_icon_class.visible = true
		check_icon_modern.visible = false
	else:
		check_icon_class.visible = false
		check_icon_modern.visible = true

		
	
