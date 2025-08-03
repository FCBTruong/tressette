extends RefCounted
class_name InventoryMgr


var current_cardback: int = g.v.game_constants.CARDBACK_IDS.CAT

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
		_:
			return "res://assets/images/card_tressette/card_back.png"  # fallback

func get_image_avatar_frame(id):
	match id:
		g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT:
			return "res://assets/images/lobby/avatar_border.png"
		g.v.game_constants.AVATAR_FRAME_IDS.SEASON:
			return "res://assets/images/items/frames/frame_01.png"
		g.v.game_constants.AVATAR_FRAME_IDS.VICTORY:
			return "res://assets/images/items/frames/frame_victory.png"
		g.v.game_constants.AVATAR_FRAME_IDS.VIP:
			return "res://assets/images/items/frames/card_back_02.png"
	return ""
	
func get_image_item(item_id: int) -> String:
	var item_type = item_id / 1000
	if item_type == g.v.game_constants.CARDBACK_TYPE:
		return get_image_cardback(item_id)
	elif item_type == g.v.game_constants.AVATAR_FRAME_TYPE:
		return get_image_avatar_frame(item_id)
	return ""

func get_icon_crypstal():
	return "res://assets/images/lobby/icon_gold.png"
