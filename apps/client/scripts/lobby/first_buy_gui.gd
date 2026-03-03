extends Node

@onready var main_pn = find_child("Main")
@onready var price_lb = find_child("PriceLb")
@onready var buy_pn_eff = find_child("BuyPnEff")
@onready var time_lb = find_child("TimeLb")
@onready var items_pn = find_child("ItemsPn")
var offer_item_node_scene = preload("res://scenes/lobby/OfferItemNode.tscn")
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
	
	#var str = tr("NO_ADS_DAYS")
	#str = str.replace("@day", str(info['no_ads_days']))
	#no_ads_lb.text = str
	
	NodeUtils.remove_all_child(self.items_pn)
	
	for r in info["rewards"]:
		var n = offer_item_node_scene.instantiate()
		items_pn.add_child(n)
		var img = n.find_child("Img")
		var lb = n.find_child("Lb")
		img.texture = load(g.v.inventory_mgr.get_image_item(r.item_id))
		
		var type = r.item_id / 1000
		var str
		if r.item_id == g.v.game_constants.CRYPSTAL_ITEM_ID:
			str = g.v.inventory_mgr.get_item_str(r.item_id, r.value, r.duration)
		else:
			str = g.v.inventory_mgr.get_name_item(r.item_id)	
		lb.text = str
	
	


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
