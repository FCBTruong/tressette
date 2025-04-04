extends Node


@onready var main_pn = find_child('MainPn')
@onready var option_bet = find_child("OptionBet")
@onready var option_player = find_child("OptionPlayer")
@onready var private_check = find_child("PrivateCheck")
@onready var bet_pn = find_child("BetPn")
@onready var option_point = find_child("OptionPoints")
@onready var fee_lb = find_child("FeeLb")
var bets = [10000]
func _ready() -> void:
	if g.v.app_version.is_in_review():
		bet_pn.visible = false
		fee_lb.visible = true
		var str = tr("FEE_CREATE")
		str = str.replace("@num", StringUtils.symbol_number(g.v.game_server_config.fee_mode_no_bet))
		fee_lb.text = str
	else:
		fee_lb.visible = false
		
	self.bets = g.v.game_server_config.tressette_bets
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	for b in bets:
		option_bet.add_item(StringUtils.point_number(b) + ' ' + g.v.game_constants.LIRA_TEXT)
		
	# find suitable option 3 x bet <= my gold
	var b_idx = find_largest_suitable_bet(g.v.player_info_mgr.my_user_data.gold)
	option_bet.select(b_idx)
	
func find_largest_suitable_bet(my_gold: int) -> int:
	var best_idx = 0  # Default to 0 in case no valid bet is found
	var largest_bet = -1

	for i in range(bets.size()):
		if g.v.game_server_config.bet_multiplier_min * bets[i] * 2 <= my_gold and bets[i] > largest_bet:
			largest_bet = bets[i]
			best_idx = i
	return best_idx  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.get_parent().remove_child(self)

func _on_create_table():
	self._on_close()
	if g.v.app_version.is_in_review():
		if g.v.player_info_mgr.my_user_data.gold < g.v.game_server_config.fee_mode_no_bet:
			g.v.game_manager.show_not_gold_recommend_shop()
			return
			
	var a = option_bet.get_selected_id()
	print("create table with bet id", a)
	var bet = bets[a]
	
	if bet * g.v.game_server_config.bet_multiplier_min > g.v.player_info_mgr.my_user_data.gold:
		g.v.game_manager.show_not_gold_recommend_shop()
		return
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.CreateTable.new()
	pkg.set_bet(bet)
	
	var player_mode = g.v.game_constants.PLAYER_MODE.SOLO
	if option_player.get_selected_id() == 1:
		player_mode = g.v.game_constants.PLAYER_MODE.TEAM
	pkg.set_player_mode(player_mode)
	var is_private = private_check.is_pressed()
	pkg.set_is_private(is_private)
	
	if g.v.app_version.is_in_review():
		pkg.set_bet_mode(false)
	else:
		pkg.set_bet_mode(true)
	var point_mode = 11
	if option_point.get_selected_id() == 1:
		point_mode = 21
	pkg.set_point_mode(point_mode)
		
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CREATE_TABLE, pkg.to_bytes())	
	
	g.v.scene_manager.add_loading(4)
