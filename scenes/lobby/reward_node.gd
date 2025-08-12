extends Panel

@onready var value_lb = find_child("ValueLb")
@onready var img = find_child("TextureRect")
func set_info(info: Reward):
	var type = info.item_id / 1000
	value_lb.text = str(info.value)
	value_lb.text = g.v.inventory_mgr.get_item_str(info.item_id, info.value, info.duration)
	
	img.texture = load(g.v.inventory_mgr.get_image_item(info.item_id))
	pass
	
