extends Panel


@onready var item_img: TextureRect = find_child("ItemImg")
@onready var label = find_child("Label")

var _info
func set_info(data: InventoryItem):
	_info = data
	var is_own = true
	var img_path = g.v.inventory_mgr.get_image_item(data.item_id)
	item_img.texture = load(img_path) 
	
	if _info.expire_time == g.v.game_constants.ITEM_PERMANENT_TIME: # -1
		label.text = tr("PERMANENT")
	else:
		var remain_secs = _info.expire_time - g.v.game_manager.get_timestamp_server()
		if remain_secs < 0:
			is_own = false
		else:
			var str_time = StringUtils.format_time2(remain_secs)
			label.text = str_time
	data.is_own = is_own
	if not is_own:
		self.modulate.a = 0.5
		self.label.text = '-'
	else:
		self.modulate.a = 1
	
func on_touch():
	g.v.scene_manager.inventory_gui.on_preview_item(_info)
