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
	var effect := randi() % 3
	_interact_count += 1
	print("[Altar] Interaction #%d triggered — effect %d" % [_interact_count, effect])

	match effect:
		0:
			# Effect 1: Change player scale (toggle between tiny / normal / giant)
			var scales := [Vector3(0.4, 0.4, 0.4), Vector3(1.0, 1.0, 1.0), Vector3(2.0, 2.0, 2.0)]
			var new_scale: Vector3 = scales[_interact_count % 3]
			_player_ref.scale = new_scale
			print("[Altar] EFFECT — Scale changed! Player is now scale: %s" % str(new_scale))
		1:
			# Effect 2: Launch player upwards
			var launch_strength: float = 15.0
			_player_ref.velocity.y = launch_strength
			print("[Altar] EFFECT — Player launched into the air! 🚀")
		2:
			# Effect 3: Print Victory message
			print("╔══════════════════════════╗")
			print("║       🏆 VICTORY! 🏆      ║")
			print("╚══════════════════════════╝")
			print("[Altar] EFFECT — Victory message printed!")
