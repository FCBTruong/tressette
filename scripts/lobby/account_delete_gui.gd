extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@onready var check_confirm = find_child("CheckConfirm")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_close():
	self.queue_free()
	
func _delete_account():
	if not check_confirm.is_pressed():
		SceneManager.show_toast("PLEASE_CONFIRM_DELETE")
		return
	GameManager.request_delete_account()
	SceneManager.add_loading(5)
