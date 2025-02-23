extends Node

@onready var no_friend_lb = find_child("NoFriendsLb")
@onready var friends_container = find_child("FriendsContainer")
var friend_node_scene = preload("res://scenes/board/FriendInviteNode.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
		
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.queue_free()
