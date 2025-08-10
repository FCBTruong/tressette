extends Panel


@onready var item_img: TextureRect = find_child("ItemImg")
@onready var label = find_child("Label")
@onready var pn_highlight = find_child("PnHighlight")
@onready var main: Control = find_child("Main")
@onready var timer: Timer = find_child("Timer")
var info
func set_info(data: InventoryItem):
	var type = data.item_id / 1000
	info = data
	var is_own = data.is_own()
	if type == g.v.game_constants.AVATAR_TYPE:
		item_img.set_avatar(str(data.item_id))
	else:
		var img_path = g.v.inventory_mgr.get_image_item(data.item_id)
		item_img.texture = load(img_path) 
	if type == g.v.game_constants.ITEM_TYPE_STACKABLE:
		label.text = StringUtils.point_number(data.value)
	else:
		if info.expire_time == g.v.game_constants.ITEM_PERMANENT_TIME: # -1
			label.text = tr("PERMANENT")
		else:
			if is_own:
				update_time_countdown()
				timer.start()

		if not is_own:
			self.main.modulate.a = 0.5
			self.label.text = '-'
		else:
			self.main.modulate.a = 1
		if type == g.v.game_constants.AVATAR_TYPE:
			self.label.visible = false
			self.custom_minimum_size = Vector2(87, 87)
			item_img.position = main.size / 2 - item_img.size / 2
	
	
func on_touch():
	g.v.scene_manager.inventory_gui.on_preview_item(self)

func on_highlight():
	pn_highlight.visible = true
	pass
func de_highlight():
	pn_highlight.visible = false
	pass

func update_time_countdown():
	var remain_secs = info.expire_time - g.v.game_manager.get_timestamp_server()
	if remain_secs < 0:
		on_end_time()
		return
	var str_time = StringUtils.format_time2(remain_secs)
	label.text = str_time


func on_end_time():
	timer.stop()
	pass
