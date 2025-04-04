extends Node

@onready var main_pn = find_child('Main')
@onready var gold_lb = find_child('GoldLb')
@onready var price_lb = find_child('PriceLb')
@onready var apple_icon = find_child('AppleIcon')
@onready var chplay_icon = find_child("ChplayIcon")
@onready var paypal_icon = find_child("PaypalIcon")
@onready var no_ads_pn = find_child("HBoxNoAds")
@onready var no_ads_lb = find_child("NoAdsLb")
@onready var gold_icon = find_child("GoldIcon")
var info: PackInfo
var index
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apple_icon.visible = g.v.config.get_platform() == g.v.config.PLATFORMS.IOS
	chplay_icon.visible = g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID
	paypal_icon.visible = g.v.config.get_platform() == g.v.config.PLATFORMS.WEB
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func effect_appear(delay: float) -> void:
	var default_pos = main_pn.position
	main_pn.modulate.a = 0
	var tween = create_tween()
	main_pn.position.x = default_pos.x + 200
	tween.tween_property(main_pn, 'position', default_pos, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5).set_delay(delay)
	
func set_info(p_info, idx):
	index = idx
	info = PackInfo.new()
	info.pack_id = p_info['pack_id']
	info.gold = p_info['gold']
	info.no_ads_days = p_info['no_ads_days']
	if info.no_ads_days > 0:
		no_ads_pn.visible = true
		var str = tr("NO_ADS_DAYS")
		str = str.replace("@day", str(info.no_ads_days))
		no_ads_lb.text = str
	else:
		no_ads_pn.visible = false
	print('set info pack', info.pack_id)
	var price = g.v.payment_mgr.get_price_pack(info.pack_id)
	price_lb.text = price
	gold_lb.text = StringUtils.point_number(info.gold)
	
	gold_icon.texture = load("res://assets/images/lobby/shop/pack_0" + str(index + 1) + ".png")
	
func _click_buy():
	g.v.payment_mgr.buy_pack(info.pack_id)
