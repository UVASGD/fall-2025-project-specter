extends ColorRect

var old_mm : Input.MouseMode

func _on_resume_pressed() -> void:
	close_menu()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Source/Scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if self.visible:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	self.show()
	get_tree().paused = true
	old_mm = Input.mouse_mode
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_menu() -> void:
	Input.set_mouse_mode(old_mm)
	self.hide()
	get_tree().paused = false
