extends Button

# Customizable properties
@export var zoom_scale: Vector2 = Vector2(0.9, 0.9)  # Scale when clicked
@export var zoom_duration: float = 0.1  # Duration of the zoom animation
@export var anchor_point: Vector2 = Vector2(0.5, 0.5)  # Custom anchor point (default: center)

var tween: Tween

func _ready():
	focus_mode = FOCUS_NONE
	# Set the pivot_offset based on the anchor point
	pivot_offset = Vector2(size.x * anchor_point.x, size.y * anchor_point.y)
	
	# Connect button signals
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))

func _on_button_down():
	# Zoom in when pressed
	tween = create_tween()
	tween.tween_property(self, "scale", zoom_scale, zoom_duration).set_trans(Tween.TRANS_LINEAR)

func _on_button_up():
	SoundManager.play_click()
	# Zoom back to normal when released
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), zoom_duration).set_trans(Tween.TRANS_LINEAR)
