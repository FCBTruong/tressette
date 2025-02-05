extends Node

@onready var fps_lb = find_child('FpsLb')
@onready var main_pn = find_child("MainPn")
@onready var line_edit_gold = find_child("LineEditGold")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_pn.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fps_lb.text = str(Engine.get_frames_per_second())
	pass

func _click_btn():
	main_pn.visible = !main_pn.visible

func _input(event):
	if Config.CURRENT_MODE != Config.MODES.LOCAL:
		return
		
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_T:
				SceneManager.add_loading(5)
				#print('search friend')
				#FriendManager.search_friend(1000002)
				#SceneManager.show_toast('hello everyone')
				pass
			if event.keycode == KEY_W:
				SceneManager.clear_loading()
				#print('search friend')
				#FriendManager.search_friend(1000002)
				#SceneManager.show_toast('hello everyone')
				pass

func _click_cheat_goldbtn():
	var gold = int(line_edit_gold.text)
	print('golll', gold)
	
	var pkg = GameConstants.PROTOBUF.PACKETS.CheatGoldUser.new()
	pkg.set_gold(gold)
	GameClient.send_packet(GameConstants.CMDs.CHEAT_GOLD_USER, pkg.to_bytes())
	pass
	
func _cheat_gold(gold: int):
	pass
