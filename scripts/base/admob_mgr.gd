extends Node
class_name AdmobMgr
@onready var admob = $"../Admob"

var is_initialized: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	g.admob_mgr = self
	admob.initialize()

func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	is_initialized = true
	print("_on_admob_initialization_completed")
	
func _on_banner_pressed():
	if is_initialized:
		admob.load_banner_ad()
		await admob.banner_ad_loaded
		admob.show_banner_ad()

func _on_interstitial_pressed():
	if is_initialized:
		admob.load_interstitial_ad()
		await admob.interstitial_ad_loaded
		admob.show_interstitial_ad()
		
func _on_reward_pressed():
	if is_initialized:
		admob.load_rewarded_ad()
		await admob.rewarded_ad_loaded
		admob.show_rewarded_ad()
		
func _on_reward_interstitial_pressed():
	if is_initialized:
		admob.load_rewarded_interstitial_ad()
		await admob.rewarded_interstitial_ad_loaded
		admob.show_rewarded_interstitial_ad()


func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	print("reward addded")
	pass # Replace with function body.


func _on_admob_rewarded_interstitial_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	print("reward interstitial addded")
	pass # Replace with function body.
