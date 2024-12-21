extends Node


# Called when the node enters the scene tree for the first time.
var my_card_panel
var play_ground
func _ready() -> void:
	my_card_panel = find_child('MyCardPanel')
	play_ground = find_child('PlayGround')
	# create players
	create_players(2)
	_init_my_cards()
	pass # Replace with function body.

# Function to create players
func create_players(player_count: int) -> void:
	var player_scene = load("res://scenes/board/Player.tscn")  # Load player scene
	
	for i in range(player_count):
		var player_instance = player_scene.instantiate()  # Create a new player instance
		player_instance.name = "Player_%d" % i  # Name the player nodes uniquely
		
				# Access and set properties from Player.gd
		player_instance.set_properties("Player_%d" % i, 100 - i * 10)
		print(i)
		
		var player_pos_node = null
		if i == 0:
			player_pos_node = find_child('PlayerPos1')
		else:
			player_pos_node = find_child('PlayerPos2')
			
		player_instance.position = player_pos_node.position
		
		# Add to the current scene
		play_ground.add_child(player_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func back_to_lobby() -> void:
	SceneManager.switch_scene("res://scenes/LobbyScene.tscn")
	
func _init_my_cards() -> void:
	var card_scene = load("res://scenes/board/Card.tscn")
	for i in range(10):
		var card = card_scene.instantiate()
		my_card_panel.add_child(card)
		card.position = Vector2(60 * i , 0)
		
func _open_chat_gui() -> void:
	SceneManager.open_gui("res://scenes/guis/GameChatGUI.tscn")
