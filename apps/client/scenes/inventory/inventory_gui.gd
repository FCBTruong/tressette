extends Control

@onready var main_pn = find_child("MainPn")
@onready var tab_container: TabContainer = find_child("TabContainer")
@onready var grid_container_avatar_frame: GridContainer = find_child("GridContainerAvatarFrame")
@onready var grid_container_cardback: GridContainer = find_child("GridContainerCardBack")
@onready var grid_container_carpet: GridContainer = find_child("GridContainerCarpet")
@onready var grid_container_avatar: GridContainer = find_child("GridContainerAvatar")
@onready var grid_container_items: GridContainer = find_child("GridContainerItems")

const TAB_AVATAR_FRAME = 0
const TAB_CARDBACK = 1
const TAB_AVATAR = 2
const TAB_CARPET = 3
const TAB_ITEMS = 4 # others
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
@onready var in_use_lb = find_child("InUseLb")
@onready var avatar_img = find_child("AvatarImg")
@onready var buy_options = find_child("BuyOptions")
@onready var price_lb = buy_pn.find_child("PriceLb")
var invetory_buy_option_scene = load("res://scenes/inventory/InventoryBuyOptionNode.tscn")
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
func _update_item_list_avatar_frame(pick_preview: bool = false, preview_item_id: int = -1):
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
			if preview_item_id != -1 and preview_item_id != item.item_id:
				continue
			pick_preview = false
			on_preview_item(n)
	
func _update_item_list_cardback(pick_preview: bool = false, preview_item_id: int = -1):
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
			if preview_item_id != -1 and preview_item_id != item.item_id:
				continue
			pick_preview = false
			on_preview_item(n)


func _update_item_list_carpet(pick_preview: bool = false, preview_item_id: int = -1):
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
			if preview_item_id != -1 and preview_item_id != item.item_id:
				continue
			pick_preview = false
			on_preview_item(n)
			
func _update_item_list_items(pick_preview: bool = false, preview_item_id: int = -1):
	if not grid_container_items:
		return
	for child in grid_container_items.get_children():
		child.queue_free()
		
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.ITEM_TYPE_STACKABLE:
			continue
		if item.value == 0:
			continue
		var n = item_node_scene.instantiate()
		grid_container_items.add_child(n)
		n.set_info(item)
		if pick_preview:
			if preview_item_id != -1 and preview_item_id != item.item_id:
				continue
			pick_preview = false
			on_preview_item(n)

func _update_item_list_avatar(pick_preview: bool = false, preview_item_id: int = -1):
	if not grid_container_avatar:
		return
	for child in grid_container_avatar.get_children():
		child.queue_free()
	var avt_using = g.v.player_info_mgr.get_avatar_id_using()
	for item in items:
		var type = item.item_id / 1000
		if type != g.v.game_constants.AVATAR_TYPE:
			continue
		if item.item_id == -1:
			var avt_third_party = g.v.player_info_mgr.my_user_data.avatar_third_party
			if not avt_third_party.begins_with("https://"):
				continue
		var n = item_node_scene.instantiate()
		grid_container_avatar.add_child(n)
		n.set_info(item)
		if pick_preview:
			if item.item_id == avt_using:
				on_preview_item(n)
				
var current_tab = 0
func _on_tab_container_tab_changed(tab: int, preview_item_id = -1) -> void:
	current_tab = tab
	if tab == TAB_AVATAR_FRAME:
		_update_item_list_avatar_frame(true, preview_item_id)
	elif tab == TAB_CARDBACK:
		_update_item_list_cardback(true, preview_item_id)
	elif tab == TAB_CARPET:
		_update_item_list_carpet(true, preview_item_id)
	elif tab == TAB_AVATAR:
		_update_item_list_avatar(true, preview_item_id)
	elif tab == TAB_ITEMS:
		_update_item_list_items(true, preview_item_id)
	pass # Replace with function body.


func force_reload():
	var cur_preview_id = preview_info.item_id if preview_info else -1

	_on_tab_container_tab_changed(current_tab, cur_preview_id)
	
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
	elif type == g.v.game_constants.AVATAR_TYPE:
		avatar_pn.visible = true
		preview_img.visible = false
		avatar_img.set_avatar(str(info.item_id))
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
		if len(info.shop) > 0:
			buy_pn.visible = true
			NodeUtils.remove_all_child(buy_options)
			var picked = false
			for s in info.shop:
				var buy_opt = invetory_buy_option_scene.instantiate()
				buy_options.add_child(buy_opt)
				buy_opt.set_info(s)
				if not picked:
					click_check_buy_option(buy_opt)
					picked = true
		else:
			buy_pn.visible = false
	
	in_use_lb.visible = false
	if info.is_own():
		not_own_lb.visible = false
		if g.v.inventory_mgr.is_using(info.item_id):
			in_use_lb.visible = true
			use_btn.visible = false
		else:
			use_btn.visible = true
	else:
		not_own_lb.visible = true
		use_btn.visible = false

var cur_shop_pack
func click_check_buy_option(n):
	for c in buy_options.get_children():
		if c == n:
			cur_shop_pack = c.info
			c.on_selected()
			var price = c.get_price()
			price_lb.text = StringUtils.point_number(price)
		else:
			c.de_selected()
	pass
	
func _on_use_btn_pressed() -> void:
	if not preview_info:
		return
	g.v.inventory_mgr.use_item(preview_info.item_id)
	var type = preview_info.item_id / 1000
	if type != g.v.game_constants.ITEM_TYPE_STACKABLE:
		self.use_btn.visible = false
		self.in_use_lb.visible = true


func _on_buy_btn_pressed() -> void:
	if not preview_info:
		return
	var price = cur_shop_pack['price']
	if price > g.v.player_info_mgr.my_user_data.gold:
		g.v.game_manager.show_not_gold()
		return
	var item_id = preview_info.item_id
	var pack_id = cur_shop_pack['id']
	g.v.inventory_mgr.buy_item(item_id, pack_id)
	pass # Replace with function body.
