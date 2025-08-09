extends RefCounted
class_name InventoryMgr


var current_cardback: int = g.v.game_constants.CARDBACK_IDS.CAT
var current_carpet: int = g.v.game_constants.CARPET_IDS.DEFAULT

var data_raw := load("res://scripts/modules/inventory/inventory.tres")
var items: Array[InventoryItem] = []
var map_item: Dictionary = {}

func _init() -> void:
	pass
const AVATAR_IDS = [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]

func _load_base_item_config():
	items.clear()
	var data = data_raw.data
	for d in data.items:
		var item = InventoryItem.new()
		item.item_id = d["item_id"]
		item.expire_time = d["expire_time"]
		item.name = d["name"]
		item.description = d["description"]
		item.shop = self.get_shop_item(item.item_id)
		items.append(item)
		map_item[item.item_id] = item
	
	# auto gen avatars
	for a in AVATAR_IDS:
		var item = InventoryItem.new()
		item.item_id = a
		item.expire_time = -1
		item.name = "AVATAR"
		item.description = ""
		items.append(item)
		map_item[item.item_id] = item

func get_current_cardback() -> String:
	return get_image_cardback(current_cardback)
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.USER_INVENTORY:
			_handle_user_inventory(payload)
		g.v.game_constants.CMDs.USE_ITEM:
			_handle_use_item(payload)
		g.v.game_constants.CMDs.BUY_ITEM:
			g.v.scene_manager.clear_loading()
			g.v.scene_manager.show_toast(tr("BUY_ITEM_SUCCESS"))
		g.v.game_constants.CMDs.INVENTORY_SHOP_CONFIG:
			_handle_shop_config(payload)

func get_image_cardback(id):
	match id:
		g.v.game_constants.CARDBACK_IDS.DEFAULT:
			return "res://assets/images/card_tressette/card_back.png"
		g.v.game_constants.CARDBACK_IDS.CAT:
			return "res://assets/images/card_tressette/card_back_04.png"
		g.v.game_constants.CARDBACK_IDS.ROYAL:
			return "res://assets/images/card_tressette/card_back_02.png"
		g.v.game_constants.CARDBACK_IDS.TAROT:
			return "res://assets/images/card_tressette/card_back_05.png"
		g.v.game_constants.CARDBACK_IDS.PIZZA:
			return "res://assets/images/card_tressette/card_back_03.png"
		_:
			return "res://assets/images/card_tressette/card_back.png"  # fallback

func get_image_avatar_frame(id):
	match id:
		g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT:
			return "res://assets/images/items/frames/frame_default.png"
		g.v.game_constants.AVATAR_FRAME_IDS.SEASON:
			return "res://assets/images/items/frames/frame_01.png"
		g.v.game_constants.AVATAR_FRAME_IDS.VICTORY:
			return "res://assets/images/items/frames/frame_victory.png"
		g.v.game_constants.AVATAR_FRAME_IDS.VIP:
			return "res://assets/images/items/frames/frame_vip.png"
	return ""
	
func get_image_carpet(id):
	match id:
		g.v.game_constants.CARPET_IDS.DEFAULT:
			return "res://assets/images/items/carpets/default.png"
		g.v.game_constants.CARPET_IDS.CLASSIC:
			return "res://assets/images/items/carpets/carpet_classic.png"
		g.v.game_constants.CARPET_IDS.ROMA_ANTICA:
			return "res://assets/images/items/carpets/carpet_01.png"
		g.v.game_constants.CARPET_IDS.VINTAGE_TRUCKER:
			return "res://assets/images/items/carpets/carpet_vintage_trucker.png"
		g.v.game_constants.CARPET_IDS.VIP:
			return "res://assets/images/items/carpets/carpet_vip.png"
		g.v.game_constants.CARPET_IDS.GLORIA_ROMANA:
			return "res://assets/images/items/carpets/carpet_gloria_romana.png"
	return ""
	
func get_image_item(item_id: int) -> String:
	var item_type = item_id / 1000
	if item_type == g.v.game_constants.CARDBACK_TYPE:
		return get_image_cardback(item_id)
	elif item_type == g.v.game_constants.AVATAR_FRAME_TYPE:
		return get_image_avatar_frame(item_id)
	elif item_type == g.v.game_constants.CARPET_TYPE:
		return get_image_carpet(item_id)
	elif item_type == g.v.game_constants.AVATAR_TYPE:
		if item_id == 0:
			var avt_third_party = g.v.player_info_mgr.my_user_data.avatar_third_party
			return avt_third_party
		return "res://assets/images/lobby/avatars/avatar_" + str(item_id) + ".png"
	return ""

func get_icon_crypstal():
	return "res://assets/images/lobby/icon_gold.png"

var my_items = []
var key_cardback
var key_carpet
func _handle_user_inventory(payload):
	_load_base_item_config()
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.UserInventory.new()
	var result_code = pkg.from_bytes(payload)
	var items = pkg.get_items()
	for item in items:
		var item_id = item.get_item_id()
		var expire_time = item.get_expire_time()
		map_item[item_id].expire_time = expire_time
		
	key_cardback = "current_cardback" + str(g.v.player_info_mgr.get_user_id())
	key_carpet = "current_carpet" + str(g.v.player_info_mgr.get_user_id())
	current_cardback = g.v.storage_cache.fetch(key_cardback, g.v.game_constants.CARDBACK_IDS.DEFAULT)
	current_carpet = g.v.storage_cache.fetch(key_carpet, g.v.game_constants.CARPET_IDS.DEFAULT)
	
	# check cardback
	if is_expire(current_cardback):
		current_cardback = g.v.game_constants.CARDBACK_IDS.DEFAULT
	if is_expire(current_carpet):
		current_carpet = g.v.game_constants.CARPET_IDS.DEFAULT
		
	# if is openning the GUI -> force hot update
	var gui = g.v.scene_manager.inventory_gui
	if gui and is_instance_valid(gui) and gui.visible == true:
		gui.force_reload()

func _handle_use_item(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.UseItem.new()
	var result_code = pkg.from_bytes(payload)
	var item_id = pkg.get_item_id()
	var type = item_id / 1000
	if type == g.v.game_constants.AVATAR_FRAME_TYPE:
		g.v.player_info_mgr.update_using_frame(item_id)
		
var shop_confg = {}
func _handle_shop_config(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InventoryShopConfig.new()
	var result_code = pkg.from_bytes(payload)
	var items = pkg.get_items()
	for item in items:
		var item_id = item.get_item_id()	
		var packs = item.get_packs()
		var arr = []
		for p in packs:
			var a = {
				"id": p.get_id(),
				"price": p.get_price(),
				"duration": p.get_duration()
			}
			arr.append(a)
		shop_confg[item_id] = arr

func _refresh_my_item_data():
	pass
	
	
func use_item(item_id):
	print("user use item: ", item_id)
	var type = item_id / 1000
	if type == g.v.game_constants.AVATAR_FRAME_TYPE:
		if item_id == g.v.player_info_mgr.my_user_data.avatar_frame:
			return
		var pkg = g.v.game_constants.PROTOBUF.PACKETS.UseItem.new()
		pkg.set_item_id(item_id)
		g.v.game_client.send_packet(g.v.game_constants.CMDs.USE_ITEM, pkg.to_bytes())
	elif type == g.v.game_constants.CARDBACK_TYPE:
		current_cardback = item_id
		g.v.storage_cache.store(key_cardback, current_cardback)
	elif type == g.v.game_constants.CARPET_TYPE:
		current_carpet = item_id
		g.v.storage_cache.store(key_carpet, current_carpet)
	elif type == g.v.game_constants.AVATAR_TYPE:
		g.v.player_info_mgr.on_update_avatar_by_id(item_id)
		var pkg = g.v.game_constants.PROTOBUF.PACKETS.ChangeAvatar.new()
		pkg.set_avatar_id(item_id)
		g.v.game_client.send_packet(g.v.game_constants.CMDs.CHANGE_AVATAR, pkg.to_bytes())
	pass


func is_expire(item_id):
	if not map_item.has(item_id):
		return true
	var expire_time = map_item[item_id].expire_time
	if expire_time == g.v.game_constants.ITEM_PERMANENT_TIME \
		or expire_time > g.v.game_manager.get_timestamp_server():
			return false
	return true
	
func is_using(item_id):
	return item_id == current_cardback \
	or item_id == current_carpet \
	or item_id == g.v.player_info_mgr.my_user_data.avatar_frame \
	or item_id == g.v.player_info_mgr.get_avatar_id_using()

func buy_item(item_id, pack_id):
	print("process buy item", item_id, " - ", pack_id)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.BuyItem.new()
	pkg.set_item_id(item_id)
	pkg.set_pack_id(pack_id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.BUY_ITEM, pkg.to_bytes())
	g.v.scene_manager.add_loading(5)
	pass
	
func get_shop_item(item_id) -> Array:
	if shop_confg.has(item_id):
		return shop_confg[item_id]
	return []
