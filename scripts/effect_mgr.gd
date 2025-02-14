extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func effect_fly_object(img: String, num: int, start_pos: Vector2, des_pos: Vector2, fly_time: float):
	for i in range(num):
		var sprite = Sprite2D.new()
		sprite.texture = load(img)
		sprite.scale = Vector2(0.2, 0.2)
		sprite.position = start_pos
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 200  # Higher layer value means it will be drawn above lower values
		canvas_layer.add_child(sprite)
		
		SceneManager.get_current_scene().add_child(canvas_layer)
	
		
		var tween = create_tween()
		# Start tween to animate from start_pos to des_pos
		sprite.position = start_pos
		tween.tween_property(
			sprite, "position", des_pos, fly_time
		).set_delay(i * 0.1)
		
		
