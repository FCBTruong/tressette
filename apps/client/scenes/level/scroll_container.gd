extends ScrollContainer

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
				get_viewport().set_input_as_handled()  # ngăn chặn scroll dọc
			else:
				dragging = false

	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		scroll_horizontal -= delta.x
		last_mouse_pos = event.position
