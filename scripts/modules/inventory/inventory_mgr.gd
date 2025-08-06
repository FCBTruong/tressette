extends RefCounted
class_name InventoryMgr


var current_cardback: int = g.v.game_constants.CARDBACK_IDS.CAT

var 	data = [
		{
			"item_id": 1000,
			"expire_time": 3333333,
			"name": "Basic frame",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 1001,
			"expire_time": 3333333,
			"name": "Basic frame",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 1002,
			"expire_time": 3333333,
			"name": "Basic frame",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 1003,
			"expire_time": 3333333,
			"name": "Basic frame",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 2000,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 2001,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 2002,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 2003,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 2004,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 4001,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 4002,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},{
			"item_id": 4003,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 4004,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		},
		{
			"item_id": 4005,
			"expire_time": 3333333,
			"name": "Card back basic",
			"description": "",
			"shop": [
				{
					"duration": 7,
					"price": 10000
				},
				{
					"duration": 30,
					"price": 20000
				}
			]
		}
	]

var items: Array[InventoryItem] = []

func _init() -> void:
	for d in data:
		var item = InventoryItem.new()
		item.item_id = d["item_id"]
		item.expire_time = d["expire_time"]
		item.name = d["name"]
		item.description = d["description"]
		items.append(item)

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
func _handle_user_inventory(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.UserInventory.new()
	var result_code = pkg.from_bytes(payload)
	var items = pkg.get_items()
	my_items = []
	for item in items:
		var item_id = item.get_item_id()
		var expire_time = item.get_expire_time()
		my_items.append({
			"item_id": item_id,
			"expire_time": expire_time
		})
	print("lennn my items", len(my_items))
