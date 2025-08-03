extends Control

@onready var level_lb = find_child("LevelLb")
@onready var vbox_gifts = find_child("VboxGifts")
@onready var received_icon = find_child("ReceivedIcon")
@onready var receive_btn = find_child("ReceiveBtn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var reward_node = preload("res://scenes/level/LevelRewardNode.tscn")
func set_info(inf):
	level_lb.text = "Lv." + str(inf["level"])
	
	var status = 0
	if status == 0:
		received_icon.visible = false
		receive_btn.visible = false
	elif status == 1:
		receive_btn.visible = true
		received_icon.visible = false
	elif status == 2:
		received_icon.visible = true
		receive_btn.visible = false
		
	for c in vbox_gifts.get_children():
		c.queue_free()
	if inf.has("gold") and inf["gold"] > 0:
		var r = reward_node.instantiate()
		vbox_gifts.add_child(r)
		var txt = load(g.v.inventory_mgr.get_icon_crypstal())
		r.find_child("RewardImg").texture = txt
		r.find_child("RewardLb").text = StringUtils.point_number(inf["gold"])

	if inf.has("items"):
		for item in inf["items"]:
			var item_id = item["item_id"]
			var duration = item["duration"]
			var r = reward_node.instantiate()
			vbox_gifts.add_child(r)
			var txt = load(g.v.inventory_mgr.get_image_item(item_id))
			r.find_child("RewardImg").texture = txt
			r.find_child("RewardLb").text = str(duration) + " DAYS"
	
	
func click_claim():
	pass
