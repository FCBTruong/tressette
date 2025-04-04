extends Node

@onready var main_pn = find_child("Main")
@onready var price_lb = find_child("PriceLb")
@onready var buy_pn_eff = find_child("BuyPnEff")
@onready var gold_lb = find_child("GoldLb")
@onready var no_ads_lb = find_child("NoAdsLb")
@onready var time_lb = find_child("TimeLb")
var info
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	info = g.v.payment_mgr.offer_first_info
	price_lb.text = g.v.payment_mgr.get_price_pack(info['pack_id'])
	gold_lb.text = StringUtils.point_number(info['gold'])
	var str = tr("NO_ADS_DAYS")
	str = str.replace("@day", str(info['no_ads_days']))
	no_ads_lb.text = str
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var time_remain = g.v.player_info_mgr.time_end_offer - g.v.game_manager.get_timestamp_client()
	if time_remain < 0:
		g.v.player_info_mgr.has_first_buy = false
		self.on_close()
		return
	self.time_lb.text = StringUtils.format_time(time_remain)
	
	
func on_close():
	self.queue_free()
	
func purchase():
	g.v.payment_mgr.buy_pack(info['pack_id'])
	self.on_close()
