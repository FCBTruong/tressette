extends RefCounted
class_name InventoryMgr


var current_cardback: int = g.v.game_constants.CARDBACK_IDS.CAT

var data_raw := load("res://scripts/modules/inventory/inventory.tres")
var items: Array[InventoryItem] = []
var map_item: Dictionary = {}

func _init() -> void:
	pass

func _load_base_item_config():
	items.clear()
	var data = data_raw.data
	for d in data.items:
		var item = InventoryItem.new()
		item.item_id = d["item_id"]
		item.expire_time = d["expire_time"]
		item.name = d["name"]
		item.description = d["description"]
		items.append(item)
		map_item[item.item_id] = item

func get_current_cardback() -> String:
	return get_image_cardback(current_cardback)
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.USER_INVENTORY:
			_handle_user_inventory(payload)

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
			return ""
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
	return ""

func get_icon_crypstal():
	return "res://assets/images/lobby/icon_gold.png"

var my_items = []
var key_cardback
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
	var current_cardback = g.v.storage_cache.fetch(key_cardback, g.v.game_constants.CARDBACK_IDS.DEFAULT)
	# check if this current_cardback is out of time, try to use another cardback valid

		

func _refresh_my_item_data():
	pass
	
	
func use_item(item_id):
	print("user use item: ", item_id)
	var type = item_id / 1000
	if type == g.v.game_constants.AVATAR_FRAME_TYPE:
		g.v.player_info_mgr.update_using_frame(item_id)
		var pkg = g.v.game_constants.PROTOBUF.PACKETS.UseItem.new()
		pkg.set_item_id(item_id)
		g.v.game_client.send_packet(g.v.game_constants.CMDs.USE_ITEM, pkg.to_bytes())
	elif type == g.v.game_constants.CARDBACK_TYPE:
		current_cardback = item_id
		g.v.storage_cache.fetch(key_cardback, current_cardback)

	pass
