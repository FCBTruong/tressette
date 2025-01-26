extends Node


# Called when the node enters the scene tree for the first time.
var table_pn
@onready var triple_table_node = find_child('TripleTableNode')
func _ready() -> void:
	var table_node_scene = load("res://scenes/lobby/rooms/TableNode.tscn")  # Load player scene
	
	var triple_bar
	table_pn = find_child('TablePn')
	for i in range(10):
		var table_node_inst = table_node_scene.instantiate()  # Create a new player instance
		table_node_inst.name = "TableNode%d" % i  # Name the player nodes uniquely
		#table_pn.add_child(table_node_inst)
		if i % 3 == 0:
			triple_bar = triple_table_node.duplicate()
			table_pn.add_child(triple_bar)
	
		triple_bar.add_child(table_node_inst)
	
	pass # Replace with function body.

func _back_to_lobby():
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_create_table_gui():
	SceneManager.open_gui('res://scenes/lobby/rooms/CreateTableGUI.tscn')
