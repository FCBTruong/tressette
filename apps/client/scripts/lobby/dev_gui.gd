extends Node

@onready var fps_lb = find_child('FpsLb')
@onready var main_pn = find_child("MainPn")
@onready var line_edit_gold = find_child("LineEditGold")
@onready var line_edit_exp = find_child("LineEditExp")
@onready var line_edit_item_type = find_child("LineEditItemType")
@onready var line_edit_item_time = find_child("LineEditItemTime")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_pn.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	fps_lb.text = str(Engine.get_frames_per_second())
	pass

func _click_btn():
	main_pn.visible = !main_pn.visible

func _input(event):
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LOCAL:
		return
		
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_T:
				#g.v.popup_mgr.add_popup("res://scenes/ranking/RankingResult.tscn", "set_info", [10, 3, 122222])
	
				g.v.game_client.send_packet(g.v.game_constants.CMDs.PAYMENT_TEST, [])
	
				return
				var rewards: Array[Reward] = [
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 1111),
					Reward.new(g.v.game_constants.CARDBACK_IDS.CAT, 1, 7)
				]
				var g = g.v.scene_manager.open_gui(
					"res://scenes/lobby/ReceiveGiftGUI.tscn")
				g.set_info(tr("YOU_RECEIVED"), rewards)
					
				return
				#var pkg = g.v.game_constants.PROTOBUF.PACKETS.PaymentAppleConsume.new()
				#pkg.set_pack_id('pack_01')
				#pkg.set_receipt_data('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')
				#g.v.game_client.send_packet(g.v.game_constants.CMDs.PAYMENT_APPLE_CONSUME, pkg.to_bytes())
	
				#g.v.scene_manager.add_loading(5)
				#print('search friend')
				#g.v.friend_mgr.search_friend(1000002)
				#g.v.scene_manager.show_toast('hello everyone')
				pass
			if event.keycode == KEY_W:
				g.v.game_constants.game_logic = GameLogic.new()
				var a = MatchData.MatchResultPlayer.new()
				a.avatar = "1"
				a.team_id = 0
				a.avatar_frame = 1001
				var b = MatchData.MatchResultPlayer.new()
				b.avatar = "2"
				b.team_id = 1
				b.avatar_frame = 1002
				var rewards: Array[Reward] = [
					Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, 10000),
					Reward.new(g.v.game_constants.EXP_ITEM_ID, 100),
					Reward.new(g.v.game_constants.AVATAR_FRAME_IDS.VICTORY, 7)
				]
				g.v.game_constants.game_logic.match_result.rewards = rewards
				
				g.v.game_constants.game_logic.match_result.win_team_id = 1
				g.v.game_constants.game_logic.match_result.is_win = true
				g.v.game_constants.game_logic.match_result.players.append(a)
				g.v.game_constants.game_logic.match_result.players.append(b)
				#g.v.game_constants.game_logic.match_result.players.append(a)
				#g.v.game_constants.game_logic.match_result.players.append(b)
				g.v.scene_manager.open_gui('res://scenes/board/GameResultGUI.tscn', true)
				pass
				g.v.scene_manager.clear_loading()
				#print('search friend')
				#g.v.friend_mgr.search_friend(1000002)
				#g.v.scene_manager.show_toast('hello everyone')
				pass
			if event.keycode == KEY_Q:
				g.v.effect_mgr.effect_fly_coin_bet_table(
					"res://assets/images/lobby/lira_icon.png",
					5,
					Vector2(240, 500),
					Vector2(600, 400),
					0.6,
					0.11,
					null,
					false
				)
				pass
			if event.keycode == KEY_ESCAPE:
				self.queue_free()

func _click_cheat_goldbtn():
	var gold = int(line_edit_gold.text)
	print('golll', gold)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.CheatGoldUser.new()
	pkg.set_gold(gold)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHEAT_GOLD_USER, pkg.to_bytes())
	pass
	
func _cheat_gold(gold: int):
	pass

func _click_add_bot():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHEAT_ADD_BOT, [])
	pass
	
func _test_share_app():
	g.v.scene_manager.show_dialog(
		tr("SHARE_GAME"),
		func():
			#g.v.storage_cache.store("share_game", 3)
			g.v.native_mgr.share_app(
				tr("SHARE_CONTENT")
			)
			pass
	)

func _click_reset_guest():
	g.v.login_mgr.save_guest_id('')
	pass

func _click_ads():
	g.v.native_mgr.rate_app()
	return
	g.admob_mgr._on_interstitial_pressed()


func _on_cheat_exp_btn_pressed() -> void:
	var gold = int(line_edit_exp.text)
	print('exppp', gold)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.CheatExpUser.new()
	pkg.set_exp(gold)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHEAT_EXP_USER, pkg.to_bytes())
	pass # Replace with function body.


func _on_cheat_item_btn_pressed() -> void:
	var type = int(line_edit_item_type.text)
	var duration = int(line_edit_item_time.text)
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.CheatItem.new()
	pkg.set_item_id(type)
	pkg.set_duration(duration)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHEAT_ITEM, pkg.to_bytes())
