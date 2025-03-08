extends Node

@onready var no_friend_lb = find_child("NoFriendsLb")
@onready var main_pn = find_child("MainPn")
@onready var friends_container = find_child("FriendsContainer")
var friend_node_scene = preload("res://scenes/board/FriendInviteNode.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	var friends = FriendManager.get_online_friends()
	
	if len(friends) == 0:
		no_friend_lb.visible = true
	else:
		no_friend_lb.visible = false
	
	for c in friends_container.get_children():
		c.queue_free()
	for f in friends:
		var n = friend_node_scene.instantiate()
		friends_container.add_child(n)
		n.set_info(f)
		
	FriendManager.send_friend_list()
		
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.queue_free()
