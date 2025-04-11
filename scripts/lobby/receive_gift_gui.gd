extends Node


@onready var main_pn = find_child("MainPn")
@onready var title_lb = find_child("TitleLb")
@onready var gold_lb = find_child("GoldLb")

func _ready() -> void:

	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	
func set_info(title, gold: int):
	self.title_lb.text = title
	self.gold_lb.text = StringUtils.symbol_number(gold)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _click_ok():
	self.queue_free()
	pass
