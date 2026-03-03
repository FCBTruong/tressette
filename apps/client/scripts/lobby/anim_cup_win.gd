extends Node


@onready var anim_cup = find_child("Anim")
@onready var light = find_child("Light")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	self.scale = Vector2(0, 0)
	anim_cup.play("default")
	tween.tween_property(
		self,
		"scale",
		Vector2(1, 1),
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		self,
		"modulate:a",
		0, 
		0.5
	).set_delay(1)
	tween.tween_callback(func():
		self.queue_free()
	).set_delay(0.1)
	
	var t = create_tween()
	t.set_loops()
	t.tween_property(
		light,
		"rotation",
		TAU,
		3
	)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
