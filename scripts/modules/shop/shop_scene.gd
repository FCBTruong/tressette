extends Node

@onready var packs_container = find_child('PacksContainer')
# Called when the node enters the scene tree for the first time.
var packs_node = []
var item_scene = preload("res://scenes/shop/ItemShopPack.tscn")
func _ready() -> void:	
	var packs = PaymentMgr.shop_packs
	
	for i in range(len(packs)):
		var instance = item_scene.instantiate()
		instance.name = 'ItemShopPack' + str(i + 1)
		packs_container.add_child(instance)
		packs_node.append(instance)
		instance.set_info(packs[i])
	
	_effect_appear()

func _effect_appear():
	for i in range(len(packs_node)):
		var n = packs_node[i]
		n.effect_appear(i * 0.1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _back_to_lobby():
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
