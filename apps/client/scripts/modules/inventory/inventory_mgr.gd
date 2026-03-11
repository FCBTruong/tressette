extends RefCounted
class_name InventoryMgr


const AVATAR_IDS = [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
const AVATAR_VIP = [14, 15, 16, 17, 18, 19, 20, 21]
const PACK_AVATAR_ANIMAL = [14, 15, 16, 17]
const SAVE_ITEMS_PATH := "user://inventory_items.json"

var current_cardback: int = g.v.game_constants.CARDBACK_IDS.CAT
var current_carpet: int = g.v.game_constants.CARPET_IDS.DEFAULT

var data_raw := load("res://scripts/modules/inventory/inventory.tres")
var shop_raw := load("res://scripts/modules/inventory/shop.tres")

var items: Array[InventoryItem] = []
var map_item: Dictionary = {}
var shop_config: Dictionary = {}

var my_items: Array = []
var key_cardback: String
var key_carpet: String
var key_avatar_frame: String

var current_avatar_frame: int = 0


func _init() -> void:
	_load_local_shop_config()
	_load_base_item_config()
	_load_local_items()
	_load_local_user_state()


func _load_base_item_config() -> void:
	items.clear()
	map_item.clear()

	var data = data_raw.data
	for d in data.items:
		var item = InventoryItem.new()
		item.item_id = int(d["item_id"])
		item.expire_time = int(d["expire_time"])
		item.name = d["name"]
		item.description = d["description"]
		item.value = 0
		item.shop = get_shop_item(item.item_id)
		items.append(item)
		map_item[item.item_id] = item

	for a in AVATAR_IDS:
		var item = InventoryItem.new()
		item.item_id = a
		item.expire_time = -1
		item.name = "AVATAR"
		item.value = 0
		item.description = ""
		item.shop = get_shop_item(item.item_id)

		items.append(item)
		map_item[item.item_id] = item


func _load_local_shop_config() -> void:
	shop_config.clear()

	if shop_raw == null or shop_raw.data == null:
		return

	var data = shop_raw.data
	for item_id_str in data.keys():
		var item_id := int(item_id_str)
		var item_data = data[item_id_str]

		if not item_data.has("shop"):
			continue

		var arr: Array = []
		for p in item_data["shop"]:
			arr.append({
				"id": int(p.get("id", 0)),
				"price": int(p.get("price", 0)),
				"duration": int(p.get("duration", 0))
			})

		shop_config[item_id] = arr


func _load_local_user_state() -> void:
	key_cardback = "current_cardback"
	key_carpet = "current_carpet"
	key_avatar_frame = "current_avatar_frame"

	current_cardback = g.v.storage_cache.fetch(
		key_cardback,
		g.v.game_constants.CARDBACK_IDS.DEFAULT
	)
	current_carpet = g.v.storage_cache.fetch(
		key_carpet,
		g.v.game_constants.CARPET_IDS.DEFAULT
	)
	current_avatar_frame = g.v.storage_cache.fetch(
		key_avatar_frame,
		g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT
	)

	if is_expire(current_cardback):
		current_cardback = g.v.game_constants.CARDBACK_IDS.DEFAULT

	if is_expire(current_carpet):
		current_carpet = g.v.game_constants.CARPET_IDS.DEFAULT
		
	if is_expire(current_avatar_frame):
		print("avatar frame expire ")
		current_avatar_frame = g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT
	
	print("avatar frame local", current_avatar_frame)


func _get_items_save_data() -> Dictionary:
	var data: Dictionary = {}
	data["items"] = []

	for item in items:
		if item.value > 0 or item.expire_time != 0:
			data["items"].append({
				"item_id": int(item.item_id),
				"expire_time": int(item.expire_time),
				"value": int(item.value)
			})

	return data


func _save_local_items() -> void:
	var file := FileAccess.open(SAVE_ITEMS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open inventory save file for writing: " + SAVE_ITEMS_PATH)
		return

	file.store_string(JSON.stringify(_get_items_save_data()))
	file.close()


func _load_local_items() -> void:
	if not FileAccess.file_exists(SAVE_ITEMS_PATH):
		return

	var file := FileAccess.open(SAVE_ITEMS_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file.close()

	if text.is_empty():
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Failed to parse inventory save file: " + SAVE_ITEMS_PATH)
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("items"):
		return

	for entry in data["items"]:
		var item_id := int(entry.get("item_id", 0))
		if not map_item.has(item_id):
			continue

		map_item[item_id].expire_time = int(entry.get("expire_time", 0))
		map_item[item_id].value = int(entry.get("value", 0))


func reload_local_data() -> void:
	_load_local_shop_config()
	_load_base_item_config()
	_load_local_user_state()
	_load_local_items()

	var gui = g.v.scene_manager.inventory_gui
	if gui and is_instance_valid(gui) and gui.visible:
		gui.force_reload()


func get_current_cardback() -> String:
	return get_image_cardback(current_cardback)


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
		g.v.game_constants.CARDBACK_IDS.NATURE:
			return "res://assets/images/card_tressette/card_back_06.png"
		_:
			return "res://assets/images/card_tressette/card_back.png"


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
		g.v.game_constants.AVATAR_FRAME_IDS.LEVEL_50:
			return "res://assets/images/items/frames/frame_lv50.png"
		g.v.game_constants.AVATAR_FRAME_IDS.LEVEL_100:
			return "res://assets/images/items/frames/frame_lv100.png"
		g.v.game_constants.AVATAR_FRAME_IDS.GOLD:
			return "res://assets/images/items/frames/frame_gold.png"
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
		if item_id == g.v.game_constants.PACK_AVATAR_ANIMAL:
			return "res://assets/images/lobby/avatars/pack_animal.png"
		if item_id == -1:
			return g.v.player_info_mgr.my_user_data.avatar_third_party
		return "res://assets/images/lobby/avatars/avatar_" + str(item_id) + ".png"
	else:
		if item_id == g.v.game_constants.CRYPSTAL_ITEM_ID:
			return "res://assets/images/lobby/icon_gold.png"
		elif item_id == g.v.game_constants.EXP_ITEM_ID:
			return "res://assets/images/board/game_result/exp_icon.png"
		elif item_id == g.v.game_constants.RENAME_CARD_ITEM_ID:
			return "res://assets/images/items/rename_card.png"
		elif item_id == g.v.game_constants.VIP_DAYS:
			return "res://assets/images/lobby/user_info_gui/vip_icon.png"

	return ""


func get_icon_crypstal():
	return "res://assets/images/lobby/icon_gold.png"


func use_item(item_id):
	print("user use item: ", item_id)

	var type = item_id / 1000
	if type == g.v.game_constants.AVATAR_FRAME_TYPE:
		if item_id == g.v.player_info_mgr.my_user_data.avatar_frame:
			return
		g.v.player_info_mgr.update_using_frame(item_id)
		current_avatar_frame = item_id
		g.v.storage_cache.store(key_avatar_frame, current_avatar_frame)

	elif type == g.v.game_constants.CARDBACK_TYPE:
		current_cardback = item_id
		g.v.storage_cache.store(key_cardback, current_cardback)

	elif type == g.v.game_constants.CARPET_TYPE:
		current_carpet = item_id
		g.v.storage_cache.store(key_carpet, current_carpet)

	elif type == g.v.game_constants.AVATAR_TYPE:
		g.v.player_info_mgr.on_update_avatar_by_id(item_id)

	elif type == g.v.game_constants.ITEM_TYPE_STACKABLE:
		if item_id == g.v.game_constants.RENAME_CARD_ITEM_ID:
			g.v.scene_manager.open_gui("res://scenes/lobby/ChangeUserNameGUI.tscn")
			return

	_save_local_items()

	var gui = g.v.scene_manager.inventory_gui
	if gui and is_instance_valid(gui) and gui.visible:
		gui.force_reload()


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

	var shop_items = get_shop_item(item_id)
	var target_pack = null

	for p in shop_items:
		if int(p.get("id", -1)) == int(pack_id):
			target_pack = p
			break

	if target_pack == null:
		return

	if not map_item.has(item_id):
		return

	var price := int(target_pack.get("price", 0))
	if g.v.player_info_mgr.my_user_data.gold < price:
		return

	g.v.player_info_mgr.consume_money(price)

	var duration = int(target_pack.get("duration", 0))

	var now_ts = g.v.game_manager.get_timestamp_client();
	map_item[item_id].expire_time = max(now_ts, map_item[item_id].expire_time) + duration * 24 * 60 * 60;
	map_item[item_id].value += 1

	_save_local_items()

	var gui = g.v.scene_manager.inventory_gui
	if gui and is_instance_valid(gui) and gui.visible:
		gui.force_reload()


func _calc_expire_time(duration: int) -> int:
	if duration == g.v.game_constants.ITEM_PERMANENT_TIME or duration < 0:
		return g.v.game_constants.ITEM_PERMANENT_TIME

	var now_ts = g.v.game_manager.get_timestamp_server()
	return now_ts + duration * 24 * 60 * 60


func get_shop_item(item_id) -> Array:
	if shop_config.has(item_id):
		return shop_config[item_id]
	return []


func get_rename_card_number():
	if map_item.has(g.v.game_constants.RENAME_CARD_ITEM_ID):
		return map_item[g.v.game_constants.RENAME_CARD_ITEM_ID].value
	return 0


func get_item_str(item_id, value, duration):
	var type = item_id / 1000
	if type == g.v.game_constants.ITEM_TYPE_STACKABLE:
		return StringUtils.point_number(value)
	else:
		if duration == g.v.game_constants.ITEM_PERMANENT_TIME:
			return tr("PERMANENT")
		else:
			return str(duration) + " " + tr("DAYS")


func get_name_item(item_id):
	if map_item.has(item_id):
		return tr(map_item[item_id].name)
	return ""


func open_gui():
	g.v.scene_manager.open_gui("res://scenes/inventory/InventoryGUI.tscn")


func is_own_avatar(id):
	return true
