extends Node

@onready var main_pn = find_child("Main")
@onready var price_lb = find_child("PriceLb")
@onready var buy_pn_eff = find_child("BuyPnEff")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	price_lb.text = g.v.payment_mgr.get_price_pack("first_buy_offer")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func on_close():
	self.queue_free()
	
func purchase():
	g.v.payment_mgr.buy_pack("first_buy_offer")
	self.on_close()
