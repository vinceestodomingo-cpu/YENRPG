extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if get_tree().current_scene.name == "MainMenu":
			return
		# Toggle pause
		var new_pause_state: bool = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state
		
		if new_pause_state:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$Control/VBoxContainer/ResumeButton.grab_focus()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	$Control/ClickSound.play()
	await $Control/ClickSound.finished
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_menu_button_pressed() -> void:
	$Control/ClickSound.play()
	await $Control/ClickSound.finished
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	$Control/ClickSound.play()
	await $Control/ClickSound.finished
	get_tree().quit()
