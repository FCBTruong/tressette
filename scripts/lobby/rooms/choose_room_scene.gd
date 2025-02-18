extends Node


# Called when the node enters the scene tree for the first time.
@onready var table_pn = find_child('TablePn')
@onready var triple_table_node = find_child('TripleTableNode')
var table_node_scene = preload("res://scenes/lobby/rooms/TableNode.tscn")  # Load player scene
signal update_table_list
func _ready() -> void:
	SignalBus.connect_global('update_table_list',Callable(self, "_update_table_list"))
	GameManager.send_get_table_list()
	SignalBus.emit_signal_global('update_table_list')
	pass # Replace with function body.

func _update_table_list():
	print('_update_table_list')
	for child in table_pn.get_children():
			child.queue_free()
	var triple_bar	
	for i in range(len(GameManager.table_list)):
		var table = GameManager.table_list[i]
		var table_node_inst = table_node_scene.instantiate()  # Create a new player instance
		table_node_inst.name = "TableNode%d" % i  # Name the player nodes uniquely
		#table_pn.add_child(table_node_inst)
		if i % 3 == 0:
			triple_bar = triple_table_node.duplicate()
			table_pn.add_child(triple_bar)
	
		triple_bar.add_child(table_node_inst)
		table_node_inst.set_info(table)
func _back_to_lobby():
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_create_table_gui():
	SceneManager.open_gui('res://scenes/lobby/rooms/CreateTableGUI.tscn')

var last_time_refresh = 0
func _refresh_list():
	if GameManager.get_timestamp_client() - last_time_refresh > 5:
		print("_refresh_list...")
		GameManager.send_get_table_list()
		last_time_refresh = GameManager.get_timestamp_client()
	else:
		print('too much request....')
	
