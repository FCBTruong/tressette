extends Node


# Called when the node enters the scene tree for the first time.
var table_pn
func _ready() -> void:
	var table_node_scene = load("res://scenes/lobby/rooms/TableNode.tscn")  # Load player scene

	table_pn = find_child('TablePn')
	for i in range(10):
		var table_node_inst = table_node_scene.instantiate()  # Create a new player instance
		table_node_inst.name = "TableNode%d" % i  # Name the player nodes uniquely
		table_pn.add_child(table_node_inst)
	
		var a = i % 3
		var b = floor(i / 3)
		table_node_inst.position = Vector2(200 + a * 280, 90 + b * 220)
		
	
	pass # Replace with function body.

func _back_to_lobby():
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
