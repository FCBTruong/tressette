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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
func _update_item_list_avatar_frame():
	for child in grid_container_avatar_frame.get_children():
		child.queue_free()
		
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.AVATAR_FRAME_TYPE:
			continue
		var n = item_node_scene.instantiate()
		grid_container_avatar_frame.add_child(n)
		n.set_info(item)
		pass

	pass
	
func _update_item_list_cardback():
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
		pass

	pass

func _update_item_list_carpet():
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
		pass

	pass
func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == TAB_AVATAR_FRAME:
		_update_item_list_avatar_frame()
	elif tab == TAB_CARDBACK:
		_update_item_list_cardback()
	elif tab == TAB_CARPET:
		_update_item_list_carpet()
	pass # Replace with function body.
