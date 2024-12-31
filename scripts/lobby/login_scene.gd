extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _login() -> void:
	GameClient.send_packet(GameConstants.CMDs.LOGIN, [])

func test_login_user_A() -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_uid(1000000)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func test_login_userB() -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_uid(1000001)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())
