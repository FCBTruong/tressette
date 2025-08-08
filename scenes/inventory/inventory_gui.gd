extends Control

@onready var main_pn = find_child("MainPn")
@onready var tab_container: TabContainer = find_child("TabContainer")
@onready var grid_container_avatar_frame: GridContainer = find_child("GridContainerAvatarFrame")
@onready var grid_container_cardback: GridContainer = find_child("GridContainerCardBack")
@onready var grid_container_carpet: GridContainer = find_child("GridContainerCarpet")
const TAB_AVATAR_FRAME = 0
const TAB_CARDBACK = 1
const TAB_AVATAR = 2
const TAB_CARPET = 3
var items = g.v.inventory_mgr.items
var preview_info
@onready var preview_name_lb = find_child("NameLb")
@onready var preview_description_lb = find_child("DescriptionLb")
@onready var preview_avatar_frame = find_child("AvatarFrame")
@onready var preview_img = find_child("ImgPreview")
@onready var avatar_pn = find_child("AvatarPn")
@onready var buy_pn = find_child("BuyPn")
@onready var use_btn = find_child("UseBtn")
@onready var not_own_lb = find_child("NotOwnLb")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	g.v.scene_manager.inventory_gui = self
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	#tab_container.current_tab = TAB_AVATAR_FRAME
	_on_tab_container_tab_changed(TAB_AVATAR_FRAME)

func _on_close():
	self.queue_free()


 
var item_node_scene = preload("res://scenes/inventory/ItemNode.tscn")
func _update_item_list_avatar_frame(pick_preview: bool = false):
	for child in grid_container_avatar_frame.get_children():
		child.queue_free()
		
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.AVATAR_FRAME_TYPE:
			continue
		var n = item_node_scene.instantiate()
		grid_container_avatar_frame.add_child(n)
		n.set_info(item)
		if pick_preview:
			pick_preview = false
			on_preview_item(n)
	
func _update_item_list_cardback(pick_preview: bool = false):
	if not grid_container_cardback:
		return
	for child in grid_container_cardback.get_children():
		child.queue_free()
		
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.CARDBACK_TYPE:
			continue
		var n = item_node_scene.instantiate()
		grid_container_cardback.add_child(n)
		n.set_info(item)
		
		if pick_preview:
			pick_preview = false
			on_preview_item(n)


func _update_item_list_carpet(pick_preview: bool = false):
	if not grid_container_carpet:
		return
	for child in grid_container_carpet.get_children():
		child.queue_free()
		
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.CARPET_TYPE:
			continue
		var n = item_node_scene.instantiate()
		grid_container_carpet.add_child(n)
		n.set_info(item)
		if pick_preview:
			pick_preview = false
			on_preview_item(n)

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == TAB_AVATAR_FRAME:
		_update_item_list_avatar_frame(true)
	elif tab == TAB_CARDBACK:
		_update_item_list_cardback(true)
	elif tab == TAB_CARPET:
		_update_item_list_carpet(true)
	pass # Replace with function body.

var recent_preview_node
func on_preview_item(item_node):
	var info: InventoryItem = item_node.info
	if is_instance_valid(recent_preview_node):
		recent_preview_node.de_highlight()
	item_node.on_highlight()
	recent_preview_node = item_node
	preview_name_lb.text = tr(info.name)
	var type = info.item_id / 1000
	if type == g.v.game_constants.AVATAR_FRAME_TYPE:
		avatar_pn.visible = true
		preview_img.visible = false
		preview_avatar_frame.update_frame_by_id(info.item_id)
	else:
		preview_img.visible = true
		var path = g.v.inventory_mgr.get_image_item(info.item_id)
		preview_img.texture = load(path)
		avatar_pn.visible = false
	preview_info = info
	preview_description_lb.text = tr(info.description)
	
	if info.expire_time == g.v.game_constants.ITEM_PERMANENT_TIME:
		buy_pn.visible = false
	else:
		buy_pn.visible = true
		
	if info.is_own:
		not_own_lb.visible = false
		use_btn.visible = true
	else:
		not_own_lb.visible = true
		use_btn.visible = false


func _on_use_btn_pressed() -> void:
	if not preview_info:
		return
	g.v.inventory_mgr.use_item(preview_info.item_id)
