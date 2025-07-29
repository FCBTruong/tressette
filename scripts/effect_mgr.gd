extends Node
class_name EffectMgr


var trail_scene = preload('res://scenes/effects/TrailNode.tscn')
func effect_fly_coin_bet_table(img: String, num: int, start_pos: Vector2, des_pos: Vector2, fly_time: float, scale, board_scene: BoardScene, should_call: bool):
	var canvas_layer = g.v.scene_manager.get_effect_layer()
	var ax = randf_range(200,500)
	
	print('effect fly coin bet')
	for i in range(num):
		var node = Node2D.new()
		canvas_layer.add_child(node)
		node.scale = Vector2(0.6, 0.6)
		var sprite = Sprite2D.new()
		node.global_position = start_pos
		node.modulate.a = 0
		
		sprite.texture = load(img)
		node.add_child(sprite)
		sprite.z_index = 1
		sprite.scale = Vector2(scale, scale)
		
		des_pos.x += randf_range(-30, 30)
		des_pos.y += randf_range(-30, 30)
		
		var trail_node = trail_scene.instantiate()
		trail_node.global_position = start_pos
		canvas_layer.add_child(trail_node)
		trail_node.find_child('Boid2D').target = node

	
		var mid_pos = (start_pos + des_pos) * 0.5
		mid_pos.y -=  ax + randf_range(-5, 5)  # Adjust this for more curvature (move control point up)

		var tween = create_tween()
		var delay = i * 0.05 + randf_range(0, 0.1)
		# Interpolate the Bezier curve using custom tween process
		tween.parallel().tween_method(
			func(value: float):
				if not node:
					return
				var bezier_pos = ((1.0 - value) * (1.0 - value)) * start_pos
				bezier_pos += 2.0 * (1.0 - value) * value * mid_pos
				bezier_pos += (value * value) * des_pos
				node.position = bezier_pos
		, 0.0, 1.0, fly_time).set_delay(delay) \
		.set_trans(Tween.TRANS_SINE)
		
		tween.parallel().tween_callback(
			func():
				g.v.sound_manager.play_coin_hit_sound()
		).set_delay(delay)
		
		tween.parallel().tween_property(
			node,
			'scale',
			Vector2(1.3, 1.3), fly_time / 2
		).set_delay((delay))
		
		tween.parallel().tween_property(
			node,
			'scale',
			Vector2(1, 1), fly_time / 2
		).set_delay((delay + fly_time / 2))
		
		tween.parallel().tween_property(
			node,
			'modulate:a', 1, 0.01
		).set_delay((delay))
		
		
		

		tween.tween_callback(node.queue_free)
		
func effect_fly_object(img: String, num: int, start_pos: Vector2, des_pos: Vector2, fly_time: float, scale = 1, delay_time = 0):
	var canvas_layer = CanvasLayer.new()
	g.v.scene_manager.get_current_scene().add_child(canvas_layer)
	canvas_layer.layer = 200  # Higher layer value means it will be drawn above lower values
	var ax = randf_range(200,500)
	for i in range(num):
		var node = Node2D.new()
		canvas_layer.add_child(node)
		node.scale = Vector2(0.6, 0.6)
		var sprite = Sprite2D.new()
		node.position = start_pos
		node.modulate.a = 0
		
		sprite.texture = load(img)
		node.add_child(sprite)
		sprite.z_index = 1
		sprite.scale = Vector2(scale, scale)
		
		des_pos.x += randf_range(-30, 30)
		des_pos.y += randf_range(-30, 30)
		
		var trail_node = trail_scene.instantiate()
		trail_node.global_position = start_pos
		canvas_layer.add_child(trail_node)
		trail_node.find_child('Boid2D').target = node

	
		var mid_pos = (start_pos + des_pos) * 0.5
		mid_pos.y -=  ax + randf_range(-5, 5)  # Adjust this for more curvature (move control point up)

		var tween = create_tween()
		var delay = delay_time + i * 0.06 + randf_range(0, 0.1)
		# Interpolate the Bezier curve using custom tween process
		tween.parallel().tween_method(
			func(value: float):
				if not node:
					return
				var bezier_pos = ((1.0 - value) * (1.0 - value)) * start_pos
				bezier_pos += 2.0 * (1.0 - value) * value * mid_pos
				bezier_pos += (value * value) * des_pos
				node.position = bezier_pos
		, 0.0, 1.0, fly_time).set_delay(delay) \
		.set_trans(Tween.TRANS_SINE)
		
		tween.parallel().tween_property(
			node,
			'scale',
			Vector2(1.3, 1.3), fly_time / 2
		).set_delay((delay))
		
		tween.parallel().tween_property(
			node,
			'scale',
			Vector2(1, 1), fly_time / 2
		).set_delay((delay + fly_time / 2))
		
		tween.parallel().tween_property(
			node,
			'modulate:a', 1, 0.01
		).set_delay((delay))
		

		tween.tween_callback(node.queue_free)
		
