extends Node

@onready var main_pn = find_child("MainPn")
@onready var content = find_child("Content")
@onready var thanks_lb = find_child("ThanksLb")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	thanks_lb.visible = false
	content.visible = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _finish_rating():
	thanks_lb.visible = true
	content.visible = false
	pass

func _on_close():
	self.queue_free()
	
func rate_5():
	g.v.native_mgr.rate_app()
	_finish_rating()
	
func rate_4():
	g.v.native_mgr.rate_app()
	_finish_rating()
	
func rate_3():
	_finish_rating()
	
func rate_2():
	_finish_rating()
	
func rate_1():
	_finish_rating()
