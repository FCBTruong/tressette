extends Panel

@onready var value_lb = find_child("ValueLb")
@onready var img = find_child("TextureRect")
func set_info(info: Reward):
	var type = info.item_id / 1000
	value_lb.text = str(info.value)
	if type == g.v.game_constants.CRYPSTAL_TYPE:
		value_lb.text = StringUtils.symbol_number(info.value)
	else:
		if info.duration > 0:
			value_lb.text = str(info.duration) + " " + tr("DAYS")
	img.texture = load(g.v.inventory_mgr.get_image_item(info.item_id))
	pass
	
