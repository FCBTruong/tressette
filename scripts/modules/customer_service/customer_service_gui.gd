extends Node

@onready var main_pn = find_child('MainPn')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0.5
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.4)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close() -> void:
	self.get_parent().remove_child(self)
