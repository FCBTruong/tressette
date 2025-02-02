extends Node


signal ok_pressed
signal close_pressed

@onready var message_label: Label = find_child('MessageLb')
@onready var main_pn = find_child('MainPn')
@onready var cancel_btn = find_child('CancelBtn')
@onready var close_btn = find_child("CloseBtn")

func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	
func set_message(message: String):
	message_label.text = message

func _on_ok_button_pressed():
	emit_signal("ok_pressed")
	self.get_parent().remove_child(self)

func _on_close_button_pressed():
	emit_signal("close_pressed")
	self.get_parent().remove_child(self)
	
func set_show_cancel_btn(show_cancel_btn):
	if show_cancel_btn:
		cancel_btn.visible = true
	else:
		cancel_btn.visible = false
func hide_close_cancel():
	self.close_btn.visible = false
	cancel_btn.visible = false
