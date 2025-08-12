extends Node


@onready var main_pn = find_child('MainPn')
@onready var option_bet = find_child("OptionBet")
@onready var option_player = find_child("OptionPlayer")
@onready var private_check = find_child("PrivateCheck")
@onready var option_point = find_child("OptionPoints")
@onready var fee_lb = find_child("FeeLb")
var bets = [10000]
func _ready() -> void:

	fee_lb.visible = true
	var str = tr("FEE_CREATE")
	str = str.replace("@num", StringUtils.symbol_number(g.v.game_server_config.fee_mode_no_bet))
	fee_lb.text = str


	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.get_parent().remove_child(self)

func _on_create_table():
	self._on_close()

	if g.v.player_info_mgr.my_user_data.gold < g.v.game_server_config.fee_mode_no_bet:
		g.v.game_manager.show_not_gold_recommend_shop()
		return
			


	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.CreateTable.new()
	
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
