extends Node

@onready var main_pn = find_child('MainPn')
@onready var sent_pn = find_child("SentPn")
@onready var content = find_child("Content")
@onready var content_edit = find_child("TextEdit")

static var is_sent: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0.5
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.4)
	
	_update_state()
	
func _update_state():
	if is_sent:
		sent_pn.visible = true
		content.visible = false
	else:
		sent_pn.visible = false
		content.visible = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close() -> void:
	self.get_parent().remove_child(self)
	
func _click_send():
	is_sent = true
	#
	_update_state()
	
	# send to server
	var str = content_edit.text
	
	str = StringUtils.sub_string(str, 500)
	content_edit.text = str
	
	var pkg = GameConstants.PROTOBUF.PACKETS.CustomerServiceReport.new()
	pkg.set_report_type(0)
	pkg.set_report_content(str)
	GameClient.send_packet(GameConstants.CMDs.CUSTOMER_SERVICE_REPORT, pkg.to_bytes())
	pass

func click_fb_fanpage():
	OS.shell_open("https://www.facebook.com/profile.php?id=61573779305884")
