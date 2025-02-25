extends Node


# Called when the node enters the scene tree for the first
var avatars = []
var current_id: int = -1
var SIZE_LIST = 15
@onready var vbox_cont = find_child("VBoxContainer")
func _ready() -> void:
	StorageCache.store("open_picking_avatar_gui", 1)
	var my_avt = PlayerInfoMgr.my_user_data.avatar
	var avt_third_party = PlayerInfoMgr.my_user_data.avatar_third_party
	if my_avt.begins_with("https://"):
		current_id = -1
	else:
		current_id = int(PlayerInfoMgr.my_user_data.avatar)

	avatars = get_all_avatar_children(self.vbox_cont)
	for a in avatars:
		a.visible = false
	
	var idx = 0
	var MAX_AVATAR_ID = GameConstants.MAX_AVATAR_ID
	for i in range(MAX_AVATAR_ID + 1):
		var a = avatars[i]
		var avt = a.find_child('AvatarImg')
		if i == 0:
			if avt_third_party.begins_with("https://"):
				avt.set_avatar(avt_third_party)
				a.visible = true
				a.id = -1
				# avatar third party
			continue
		var id = i
		avt.set_avatar(str(id))
		a.visible = true
		a.id = id
		
	_update_picking_state()
	
	SignalBus.connect_global('on_picking_avatar', Callable(self, "_received_pick_avatar"))


func get_all_avatar_children(node: Node) -> Array:
	var avatar_children = []
	
	for child in node.get_children():
		if child.name.begins_with("Avatar"):
			avatar_children.append(child)
		else:
			# Recursively check sub-children
			avatar_children.append_array(get_all_avatar_children(child))
	
	return avatar_children


func _received_pick_avatar(id):
	if id == current_id:
		return
	current_id = id
	_update_picking_state()
	
	var avatar = str(current_id)
	if current_id == -1:
		avatar = PlayerInfoMgr.my_user_data.avatar_third_party
	PlayerInfoMgr.on_update_avatar(avatar)
	# send to server to update change
	var pkg = GameConstants.PROTOBUF.PACKETS.ChangeAvatar.new()
	pkg.set_avatar_id(current_id)
	GameClient.send_packet(GameConstants.CMDs.CHANGE_AVATAR, pkg.to_bytes())
	
func _update_picking_state():
	for i in range(SIZE_LIST):
		var a = avatars[i]
		if not a.visible:
			continue
		if a.id == current_id:
			a.on_hightlight(true)
		else:
			a.on_hightlight(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.get_parent().remove_child(self)
