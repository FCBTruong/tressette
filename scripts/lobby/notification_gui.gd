extends Node


signal ok_pressed
signal close_pressed

@onready var message_label: Label = find_child('MessageLb')

func set_message(message: String):
	message_label.text = message

func _on_ok_button_pressed():
	emit_signal("ok_pressed")

func _on_close_button_pressed():
	emit_signal("close_pressed")

#func _click_ok():
	#WebsocketClient.connect_to_server()
	#self.get_parent().remove_child(self)
	#SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
	#pass
