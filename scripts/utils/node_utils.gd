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
