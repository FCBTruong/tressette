extends Node

@onready var mission_name_lb = find_child("MissionNameLb")
@onready var reward_lb = find_child('MissionRewardLb')
@onready var action_btn = find_child("DoItBtn")
@onready var claim_btn = find_child("ClaimBtn")
@onready var refresh_state = find_child("RefreshState")
@onready var completed_lb = find_child("CompletedLb")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var info
func set_mission_info(inf):
	info = inf
	mission_name_lb.text = inf.name
	reward_lb.text = StringUtils.point_number(inf.gold)
	
	var status: int = inf.status
	
	self.action_btn.visible = false
	self.claim_btn.visible = false
	self.refresh_state.visible = false
	self.completed_lb.visible = false
	if status == 0:
		# to do
		self.action_btn.visible = true
	elif status == 1:
		# claim
		self.claim_btn.visible = true
	elif status == 2:
		# completed
		if info.time_refresh == -1:
			self.completed_lb.visible = true
		else:
			self.refresh_state.visible = true
	pass

func do_mission():
	pass
	
func claim_reward():
	pass
