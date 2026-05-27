extends Area3D

## Interaction zone attached to the central KayKit prop (Chest).
## Listens for the 'interact' action (E key) when the Player is inside.
## On interact, randomly picks one of three effects:
##   1. Change the player's scale
##   2. Launch the player upwards
##   3. Print "Victory!" to the console

var _player_inside: bool = false
var _player_ref: CharacterBody3D = null

# Track number of interactions so we can cycle through effects for testing variety
var _interact_count: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("[Altar] Interaction zone ready. Approach and press E to interact.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _player_inside and _player_ref != null:
		_trigger_random_effect()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = true
		_player_ref = body as CharacterBody3D
		print("[Altar] Player entered interaction zone — press E to interact!")
		# Show HUD hint if player has the method
		if _player_ref.has_method("show_interact_hint"):
			_player_ref.show_interact_hint("[E]  Open Chest")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = false
		_player_ref = null
		print("[Altar] Player left interaction zone.")
		# Hide the HUD hint (find player in group)
		for p in get_tree().get_nodes_in_group("Player"):
			if p.has_method("hide_interact_hint"):
				p.hide_interact_hint()

func _trigger_random_effect() -> void:
	print("[Altar] Transitioning to Level 2!")
	var next_level_path = "res://Scene/Level2.tscn"
	if ResourceLoader.exists(next_level_path):
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("[Altar] ERROR: Level2.tscn not found! Re-run gen_levels.py")
