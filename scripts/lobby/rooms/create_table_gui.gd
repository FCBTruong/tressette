extends Node


@onready var main_pn = find_child('MainPn')
@onready var option_bet = find_child("OptionBet")
@onready var option_player = find_child("OptionPlayer")
@onready var private_check = find_child("PrivateCheck")

var bets = [10000]
func _ready() -> void:
	self.bets = GameServerConfig.tressette_bets
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	for b in bets:
		option_bet.add_item(StringUtils.point_number(b) + ' ' + GameConstants.LIRA_TEXT)
		
	# find suitable option 3 x bet <= my gold
	var b_idx = find_largest_suitable_bet(PlayerInfoMgr.my_user_data.gold)
	option_bet.select(b_idx)
	
func find_largest_suitable_bet(my_gold: int) -> int:
	var best_idx = 0  # Default to 0 in case no valid bet is found
	var largest_bet = -1

	for i in range(bets.size()):
		if GameServerConfig.bet_multiplier_min * bets[i] <= my_gold and bets[i] > largest_bet:
			largest_bet = bets[i]
			best_idx = i
	return best_idx  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.get_parent().remove_child(self)

func _on_create_table():
	var a = option_bet.get_selected_id()
	print("create table with bet id", a)
	var bet = bets[a]
	
	if bet * GameServerConfig.bet_multiplier_min > PlayerInfoMgr.my_user_data.gold:
		GameManager.show_not_gold_recommend_shop()
		return
	
	var pkg = GameConstants.PROTOBUF.PACKETS.CreateTable.new()
	pkg.set_bet(bet)
	
	var player_mode = GameConstants.PLAYER_MODE.SOLO
	if option_player.get_selected_id() == 1:
		player_mode = GameConstants.PLAYER_MODE.TEAM
	pkg.set_player_mode(player_mode)
	var is_private = private_check.is_pressed()
	pkg.set_is_private(is_private)
	GameClient.send_packet(GameConstants.CMDs.CREATE_TABLE, pkg.to_bytes())
	
	SceneManager.add_loading(4)
