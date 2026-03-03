extends Node
class_name NodeUtils


static func get_center_position(node) -> Vector2:
	var global_position = node.global_position

	if node is Control:
		# For Control nodes, use the size property
		return global_position + (node.size / 2)
	elif node is Sprite2D and node.texture:
		# For Sprite2D, calculate based on texture size and scale
		var size = node.texture.get_size() * node.scale
		return global_position + (size / 2)
	else:
		# If no size is applicable, just return the position
		return global_position

static func set_center_pivot(node):
	var size = node.size
	node.pivot_offset = size / 2
	
	
static func update_animated_sprite(sprite: AnimatedSprite2D, tres_path: String):
	var sprite_frames = load(tres_path) as SpriteFrames
	if not sprite_frames:
		print("Failed to load .tres:", tres_path)
		return
	
	sprite.sprite_frames = sprite_frames  # Apply new SpriteFrames
	if sprite_frames.get_animation_names().size() > 0:
		sprite.animation = sprite_frames.get_animation_names()[0]  # Set first animation
		sprite.play()  # Play animation

static func remove_all_child(node):
	for c in node.get_children():
		c.queue_free()
