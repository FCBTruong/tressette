extends Node

var pn
var default_pos
var tween  # Stores the tween object
@onready var toast_lb = find_child('ToastLb')

func _ready() -> void:
	# Find the child node
	pn = find_child('Pn')
	default_pos = pn.position
	
	# Shift X so we can tween back to default at startup
	pn.position.y -= 100
	
	# Create a tween for the initial animation
	tween = create_tween()
	tween.tween_property(
		pn,
		"position",
		default_pos,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Start a timer to close after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(_close_pn)

func _close_pn() -> void:
	# Create another tween to move the panel out
	var close_tween = create_tween()
	close_tween.tween_property(
		pn,
		"position",
		default_pos - Vector2(0, 100),  # Move 300px to the right
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_toats_text(txt):
	toast_lb.text = txt
