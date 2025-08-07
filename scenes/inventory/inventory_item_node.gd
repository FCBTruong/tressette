extends Panel


@onready var item_img: TextureRect = find_child("ItemImg")
@onready var label = find_child("Label")

var _info
func set_info(data: InventoryItem):
	_info = data 
	var img_path = g.v.inventory_mgr.get_image_item(data.item_id)
	item_img.texture = load(img_path) 
	
func on_touch():
	g.v.scene_manager.inventory_gui.on_preview_item(_info)
