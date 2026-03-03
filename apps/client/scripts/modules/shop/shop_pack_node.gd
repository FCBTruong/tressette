extends Node

@onready var main_pn = find_child('Main')
@onready var gold_lb = find_child('GoldLb')
@onready var price_lb = find_child('PriceLb')
@onready var apple_icon = find_child('AppleIcon')
@onready var chplay_icon = find_child("ChplayIcon")
@onready var paypal_icon = find_child("PaypalIcon")
@onready var gold_icon = find_child("GoldIcon")
@onready var items_pn = find_child("ItemsPn")
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

	var price = g.v.payment_mgr.get_price_pack(info.pack_id)
	price_lb.text = price
	gold_lb.text = StringUtils.point_number(info.gold)
	
	gold_icon.texture = load("res://assets/images/lobby/shop/pack_0" + str(index + 1) + ".png")
	
	NodeUtils.remove_all_child(self.items_pn)
	
	var items = p_info['items'].duplicate(true)
	if info.no_ads_days > 0:
		items.append(
			Reward.new(
				g.v.game_constants.VIP_DAYS,
				1,
				info.no_ads_days
			)
		)
	
	for item in items:
		var n = shop_item_node_scene.instantiate()
		self.items_pn.add_child(n)
		n.set_info(item)
		pass
var shop_item_node_scene = preload("res://scenes/shop/ShopItemNode.tscn")
func _click_buy():
	g.v.payment_mgr.buy_pack(info.pack_id)
