extends Node


# Called when the node enters the scene tree for the first time.
@onready var table_pn = find_child('TablePn')
@onready var create_table_btn = find_child("CreateTableBtn")
@onready var triple_table_node = find_child('TripleTableNode')
@onready var lb_empty = find_child("LabelEmpty")
var table_node_scene = preload("res://scenes/lobby/rooms/TableNode.tscn")  # Load player scene
signal update_table_list

func _ready() -> void:
	g.v.signal_bus.connect_global('update_table_list',Callable(self, "_update_table_list"))
	g.v.game_manager.send_get_table_list()
	g.v.signal_bus.emit_signal_global('update_table_list')
	
	#if g.v.game_manager.is_enable_ads():
		#g.admob_mgr._on_interstitial_pressed()
	#pass # Replace with function body.

func _update_table_list():
	lb_empty.visible = true
			
	print('_update_table_list')
	for child in table_pn.get_children():
			child.queue_free()
	var triple_bar	
	lb_empty.visible = len(g.v.game_manager.table_list) == 0
	for i in range(len(g.v.game_manager.table_list)):
		var table = g.v.game_manager.table_list[i]
		var table_node_inst = table_node_scene.instantiate()  # Create a new player instance
		table_node_inst.name = "TableNode%d" % i  # Name the player nodes uniquely
		#table_pn.add_child(table_node_inst)
		if i % 3 == 0:
			triple_bar = triple_table_node.duplicate()
			table_pn.add_child(triple_bar)
	
		triple_bar.add_child(table_node_inst)
		table_node_inst.set_info(table)
func _back_to_lobby():
	g.v.scene_manager.switch_scene(g.v.scene_manager.LOBBY_SCENE)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_create_table_gui():
	g.v.scene_manager.open_gui('res://scenes/lobby/rooms/CreateTableGUI.tscn')

var last_time_refresh = 0
func _refresh_list():
	if g.v.game_manager.get_timestamp_client() - last_time_refresh > 5:
		print("_refresh_list...")
		g.v.game_manager.send_get_table_list()
		last_time_refresh = g.v.game_manager.get_timestamp_client()
	else:
		print('too much request....')
	
func _click_join_room_by_id(text):
	print('join table', text)
	var room_id = int(text)
	g.v.game_manager.join_game_by_id(room_id)
