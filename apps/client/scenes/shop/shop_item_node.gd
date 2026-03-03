extends HBoxContainer

@onready var img = find_child("Img")
@onready var lb = find_child("Lb")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_info(info: Reward):
	img.texture = load(g.v.inventory_mgr.get_image_item(info.item_id))
	lb.text = g.v.inventory_mgr.get_item_str(info.item_id, info.value, info.duration)
