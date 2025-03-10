extends Node

# DO NOT ADD ANY CHANGES HERE
# IF ADD NEED TO UPLOAD NEW APK, IOS
# CALL WHEN GAME STARTED
var save_path = "user://update.pck"
var game_init

func _init():
	print("load_resource_pack")
	ProjectSettings.load_resource_pack(save_path)

func _ready() -> void:
	print("root game....")
	await get_tree().process_frame
	var game_init = load("res://scripts/root/game_init.gd").new()	
	get_tree().root.add_child(game_init)
	

func _process(delta: float) -> void:
	pass
