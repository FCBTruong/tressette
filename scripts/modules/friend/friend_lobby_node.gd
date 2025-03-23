extends Node


@onready var name_lb = find_child('NameLb')
@onready var avatar_img = find_child('AvatarImg')
@onready var online_icon = find_child('OnlineIcon')
@onready var anim_playing = find_child("AnimPlaying")
var friend_info = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_info(f: FriendModel) -> void:
	friend_info = f
	name_lb.text = f.name
	avatar_img.set_avatar(f.avatar)
	online_icon.visible = f.is_online
	
	anim_playing.visible = false
	if f.is_playing:
		online_icon.visible = false
		anim_playing.visible = true
		anim_playing.find_child("AnimatedSprite2D").play()
	pass


func _click_info():
	g.v.friend_mgr.search_friend(friend_info.uid)
