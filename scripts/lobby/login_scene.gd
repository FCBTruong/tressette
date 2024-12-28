extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _login() -> void:
	var BaseSendPacket = preload("res://scripts/network/base_send_packet.gd")
	var c = BaseSendPacket.new()
	c.put_string('hello')
	c.put_byte(1)
	c.put_int(1000)
	c.put_string('how are you')
	GameClient.send_packet(1000, c)
	return
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
