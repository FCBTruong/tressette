extends Node

var friends: Array[FriendModel] = []
var requests: Array[FriendModel] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var a = FriendModel.new()
	a.uid = 1000
	a.name = 'Truong Nguyen'
	
	var b = FriendModel.new()
	b.uid = 1001
	b.name = 'Tomas Sheby'
	
	friends.append(a)
	friends.append(a)
	friends.append(a)
	friends.append(a)
	friends.append(a)
	friends.append(a)
	friends.append(b)
	
	requests.append(b)
	requests.append(b)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
enum FriendRequestAction {
	ACCEPT = 0,
	REJECT = 1
}
