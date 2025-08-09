
class_name FriendModel
extends RefCounted

@export var uid: int
@export var name: String
@export var avatar: String
@export var gold: int
@export var level: int
@export var is_online: bool = false
@export var is_playing: bool = true
@export var avatar_frame: int = g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT
@export var last_online_time: int = -1
