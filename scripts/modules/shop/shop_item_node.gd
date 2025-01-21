extends Node

@onready var main_pn = find_child('Main')
@onready var gold_lb = find_child('GoldLb')
@onready var price_lb = find_child('PriceLb')
var info: PackInfo
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
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
	
func set_info(p_info):
	info = PackInfo.new()
	info.pack_id = p_info['id']
	print('set info pack', info.pack_id)
	var price = PaymentMgr.get_price_pack(info.pack_id)
	price_lb.text = price
	
func _click_buy():
	PaymentMgr.buy_pack(info.pack_id)
