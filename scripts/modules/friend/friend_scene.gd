extends Node


# Called when the node enters the scene tree for the first time.
@onready var top_pn = find_child('TopPn')
@onready var request_dot = find_child('RequestDot')
@onready var request_number_lb = find_child('RequestNumberLb')
@onready var list_container = find_child('ListContainer')
var friend_node_scene = preload("res://scenes/friend/FriendNode.tscn")
func _ready() -> void:
	var tween = create_tween()
	var default_pos = top_pn.position
	top_pn.modulate.a = 0
	top_pn.position.y = default_pos.y - 100
	
	tween.parallel().tween_property(top_pn, 'position', default_pos, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
	tween.parallel().tween_property(top_pn, 'modulate:a', 1, 0.5)
	list_container.modulate.a = 0
	tween.parallel().tween_property(list_container, 'modulate:a', 1, 0.5)
	
	SignalBus.connect_global('update_friend_list', Callable(self, '_update_friends_list'))
	SignalBus.connect_global('update_friend_requests', Callable(self, '_update_friends_requests'))
	_update_friends_list()
	_update_friends_requests()
	pass # Replace with function body.

func _update_friends_list():
	for child in list_container.get_children():
		child.queue_free()

	for f in FriendManager.friends:
		var instance = friend_node_scene.instantiate()
		list_container.add_child(instance)
		instance.set_info(f)
		
	if len(FriendManager.friends) == 0:
		# Add recommend
		var recommmend_node_scene = preload("res://scenes/friend/FriendRecommendNode.tscn")
		for f in FriendManager.recommend_friends:
			var instance = recommmend_node_scene.instantiate()
			list_container.add_child(instance)
			instance.set_info(f)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _back_to_lobby():
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)

func _open_requests():
	SceneManager.open_gui("res://scenes/friend/FriendRequestsGUI.tscn")

func _on_line_edit_text_submitted(new_text: String) -> void:
	var uid = int(new_text)
	FriendManager.search_friend(uid)

func _update_friends_requests():
	request_dot.visible = len(FriendManager.requests) > 0
	request_number_lb.text = str(len(FriendManager.requests))
