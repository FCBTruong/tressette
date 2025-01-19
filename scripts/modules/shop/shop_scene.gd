extends Node

@onready var packs_container = find_child('PacksContainer')
# Called when the node enters the scene tree for the first time.
var packs_node = []
func _ready() -> void:
	for i in range(5):
		var name = 'ItemShopPack' + str(i + 1)
		var n = packs_container.find_child(name)
		packs_node.append(n)
	
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
