extends Node

@onready var main_pn = find_child('MainPn')
var tween
func _ready() -> void:
	tween = create_tween()
	var default_pos = main_pn.position
	#main_pn.modulate.a = 0
	main_pn.position.y -= 600
	
	tween.parallel().tween_property(main_pn, 'position', default_pos, 0.3).set_ease(Tween.EASE_OUT)
	#tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_close() -> void:
	if tween and tween.is_running():
		tween.kill()
	self.queue_free()
