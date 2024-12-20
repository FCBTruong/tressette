extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Properties
var player_name: String = "Default"
var health: int = 100
var uid: String = '0'
var gold: int = 0

# Function to update properties
func set_properties(name: String, health_value: int) -> void:
	player_name = name
	health = health_value
	
	var name_label = $NameLb  # Access the RichTextLabel
	if name_label:
		name_label.text = player_name
	print("Player:", player_name, "Health:", health)
	
var user_info_gui: PackedScene = preload("res://scenes/guis/UserInfoGUI.tscn")

func _open_user_info_gui():
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		var user_info_gui = load("res://scenes/guis/UserInfoGUI.tscn")
		var popup_instance = user_info_gui.instantiate()
		current_scene.add_child(popup_instance)
	else:
		print("Current Scene is null")
