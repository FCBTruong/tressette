extends Node
@onready var main_pn = find_child("MainPn")
@onready var list_player = find_child("ListPlayer")
@onready var time_lb = find_child("TimeLb")
var ranking_player_scene = preload("res://scenes/ranking/RankingPlayer.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var pos = main_pn.position
	var tween = create_tween()
	main_pn.position.y  -= 500
	#main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'position', pos, 0.3)
	#tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	for u in g.v.ranking_mgr.list_users:
		var n = ranking_player_scene.instantiate()
		list_player.add_child(n)
		n.set_info(u)
	var time_remain = 20000  # seconds

	var days = time_remain / 86400
	var hours = (time_remain % 86400) / 3600
	var minutes = (time_remain % 3600) / 60

	var parts = []
	if days > 0:
		parts.append("%dd" % days)
	if hours > 0 or days > 0:  # Always show hours if there are days
		parts.append("%dh" % hours)
	if minutes > 0 or (days == 0 and hours == 0):  # Always show minutes if no days/hours
		parts.append("%dm" % minutes)

	var str_time = ":".join(parts)
	self.time_lb.text = str_time
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close():
	self.queue_free()
