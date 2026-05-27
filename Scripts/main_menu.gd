extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	get_tree().change_scene_to_file("res://Scene/MainLevel.tscn")

func _on_exit_button_pressed() -> void:
	$ClickSound.play()
	await $ClickSound.finished
	get_tree().quit()
