extends CharacterBody3D

## Player Controller — KayKit Adventurers (Knight)
## WASD = move, Space = jump, LMB = attack, E = interact, Esc = cursor toggle
## Integrates with: HUD (CanvasLayer), AnimationPlayer on Knight model

# ── Exports ────────────────────────────────────────────────────────────────────
@export_group("Movement")
@export var speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 6.5
@export var acceleration: float = 14.0
@export var friction: float = 12.0

@export_group("Camera")
@export var camera_distance: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -50.0
@export var max_pitch: float = 35.0

@export_group("Combat")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var attack_damage: float = 50.0
@export var attack_range: float = 2.2
@export var attack_cooldown: float = 0.9
@export var attack_hit_window_start: float = 0.25  # seconds into swing when hit registers
@export var attack_hit_window_end: float = 0.55
@export var stamina_regen_rate: float = 20.0
@export var attack_stamina_cost: float = 15.0

# ── State ──────────────────────────────────────────────────────────────────────
enum PlayerState { IDLE, WALK, RUN, JUMP, ATTACK, HURT, DEAD }
var _state: PlayerState = PlayerState.IDLE

var _health: float
var _stamina: float
var _yaw: float = 0.0
var _pitch: float = -18.0
var _attack_timer: float = 0.0
var _attack_hit_done: bool = false
var _is_dead: bool = false
var _hurt_timer: float = 0.0
var _combo_count: int = 0
var _combo_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ── Anim tracking ──────────────────────────────────────────────────────────────
var _current_anim: String = ""
var _anim_names: Dictionary = {}  # mapped short names → full names found in AnimationPlayer

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var hud: CanvasLayer = $HUD
@onready var health_bar: ProgressBar = $HUD/Bars/BarsPanel/HPBar
@onready var stamina_bar: ProgressBar = $HUD/Bars/BarsPanel/StamBar
@onready var interact_label: Label = $HUD/InteractLabel
@onready var damage_flash: ColorRect = $HUD/DamageFlash
@onready var death_panel: Panel = $HUD/DeathPanel
@onready var hit_label: Label = $HUD/HitLabel
@onready var model_root: Node3D = $ModelRoot
@onready var swing_sound: AudioStreamPlayer3D = $SwingSound
@onready var hit_sound: AudioStreamPlayer3D = $HitSound

# AnimationPlayer resolved dynamically in _ready (GLB path varies by import)
var anim_player: AnimationPlayer = null

# ── Signals ────────────────────────────────────────────────────────────────────
signal health_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal player_died

# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("Player")
	_health = max_health
	_stamina = max_stamina
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.spring_length = camera_distance
	camera_pivot.rotation_degrees.x = _pitch
	health_bar.max_value = max_health
	health_bar.value = _health
	stamina_bar.max_value = max_stamina
	stamina_bar.value = _stamina
	interact_label.visible = false
	damage_flash.modulate.a = 0.0
	death_panel.visible = false
	hit_label.visible = false

	# Find AnimationPlayer
	if model_root:
		anim_player = _find_anim_player(model_root)
	if not anim_player:
		print("[Player] WARNING: No AnimationPlayer found in ModelRoot")
	else:
		_load_external_animations()
		_discover_animations()
	_play_anim("Idle")


func _load_external_animations() -> void:
	if not anim_player:
		return
	var anim_paths: Array[String] = [
		"res://Assets/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb",
		"res://Assets/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb"
	]
	var lib_idx: int = 0
	for path in anim_paths:
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path)
			if scene:
				var instance: Node = scene.instantiate()
				var ext_player: AnimationPlayer = _find_anim_player(instance)
				if ext_player:
					var lib: AnimationLibrary = ext_player.get_animation_library("")
					if lib:
						anim_player.add_animation_library("ext_%d" % lib_idx, lib)
						lib_idx += 1
				instance.queue_free()


func _find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var result: AnimationPlayer = _find_anim_player(child)
		if result:
			return result
	return null


func _discover_animations() -> void:
	if not anim_player:
		return
	var anim_list: PackedStringArray = anim_player.get_animation_list()
	var wanted: Array[String] = ["Idle", "Walk", "Run", "Attack", "Death", "Hit"]
	for w: String in wanted:
		var wl: String = w.to_lower()
		for a: String in anim_list:
			if a.to_lower().contains(wl):
				_anim_names[wl] = a
				break
		# Fallback: exact match first chars
		if not _anim_names.has(wl):
			for a: String in anim_list:
				if a.to_lower().begins_with(wl):
					_anim_names[wl] = a
					break
	# Hard fallback: if attack not found, map to first available
	if not _anim_names.has("attack") and anim_list.size() > 0:
		_anim_names["attack"] = anim_list[0]
	print("[Player] Discovered animations: ", _anim_names)


func _play_anim(short_name: String, restart: bool = false) -> void:
	if not is_instance_valid(anim_player):
		return
	var key: String = short_name.to_lower()
	var full_name: String = _anim_names.get(key, "")
	if full_name == "":
		# Try direct
		if anim_player.has_animation(short_name):
			full_name = short_name
		else:
			return
	if _current_anim == full_name and not restart:
		return
	_current_anim = full_name
	anim_player.play(full_name)


# ── Input ──────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity * 57.2958
		_pitch -= event.relative.y * mouse_sensitivity * 57.2958
		_pitch = clamp(_pitch, min_pitch, max_pitch)
		rotation_degrees.y = _yaw
		camera_pivot.rotation_degrees.x = _pitch


func _process(delta: float) -> void:
	if _is_dead:
		return


	# Attack (LMB)
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0 and _state != PlayerState.ATTACK:
		if _stamina >= attack_stamina_cost:
			_start_attack()

	# Timers
	_attack_timer = max(0.0, _attack_timer - delta)
	_hurt_timer = max(0.0, _hurt_timer - delta)
	_combo_timer = max(0.0, _combo_timer - delta)
	if _combo_timer <= 0.0:
		_combo_count = 0

	# Stamina regen
	if _state != PlayerState.ATTACK:
		_stamina = min(max_stamina, _stamina + stamina_regen_rate * delta)
		stamina_bar.value = _stamina

	# Attack hit window
	if _state == PlayerState.ATTACK:
		var elapsed: float = attack_cooldown - _attack_timer
		if elapsed >= attack_hit_window_start and elapsed <= attack_hit_window_end and not _attack_hit_done:
			_attack_hit_done = true
			_do_hit_detection()
		if _attack_timer <= 0.0:
			_set_state(PlayerState.IDLE)

	# Hurt recovery
	if _state == PlayerState.HURT and _hurt_timer <= 0.0:
		_set_state(PlayerState.IDLE)

	# Damage flash fade
	if damage_flash.modulate.a > 0.01:
		damage_flash.modulate.a = lerp(damage_flash.modulate.a, 0.0, 8.0 * delta)
	else:
		damage_flash.modulate.a = 0.0

	# Hit label fade
	if hit_label.visible:
		hit_label.modulate.a = lerp(hit_label.modulate.a, 0.0, 3.0 * delta)
		if hit_label.modulate.a < 0.05:
			hit_label.visible = false

	# Animation state machine for movement
	_update_movement_anim()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and _state != PlayerState.ATTACK:
		velocity.y = jump_velocity
		_set_state(PlayerState.JUMP)

	# Land detection
	if _state == PlayerState.JUMP and is_on_floor():
		_set_state(PlayerState.IDLE)

	# Movement (locked during attack / hurt)
	var lock_move: bool = (_state == PlayerState.ATTACK or _state == PlayerState.HURT or _state == PlayerState.DEAD)
	var move_dir: Vector2 = Vector2.ZERO
	if not lock_move:
		if Input.is_action_pressed("up"):    move_dir.y -= 1.0
		if Input.is_action_pressed("down"):  move_dir.y += 1.0
		if Input.is_action_pressed("left"):  move_dir.x -= 1.0
		if Input.is_action_pressed("right"): move_dir.x += 1.0

	var direction: Vector3 = Vector3.ZERO
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		var forward: Vector3 = -transform.basis.z
		var right: Vector3 = transform.basis.x
		direction = (forward * -move_dir.y + right * move_dir.x).normalized()

	var target_speed: float = run_speed if Input.is_action_pressed("run") else speed
	if direction:
		velocity.x = lerp(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, acceleration * delta)
		# Rotate model root to face movement direction smoothly
		if model_root:
			var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
			model_root.transform.basis = model_root.transform.basis.slerp(target_basis, 12.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()


# ── Animation Logic ─────────────────────────────────────────────────────────────
func _update_movement_anim() -> void:
	if _state == PlayerState.ATTACK or _state == PlayerState.DEAD or _state == PlayerState.HURT or _state == PlayerState.JUMP:
		return
	var moving: bool = (abs(velocity.x) + abs(velocity.z)) > 0.5
	var running: bool = moving and Input.is_action_pressed("run")
	if running:
		_set_state(PlayerState.RUN)
	elif moving:
		_set_state(PlayerState.WALK)
	else:
		_set_state(PlayerState.IDLE)


func _set_state(new_state: PlayerState) -> void:
	if _state == new_state:
		return
	_state = new_state
	match new_state:
		PlayerState.IDLE:   _play_anim("Idle")
		PlayerState.WALK:   _play_anim("Walk")
		PlayerState.RUN:    _play_anim("Run")
		PlayerState.JUMP:   _play_anim("Jump")
		PlayerState.ATTACK:
			var atk_name: String = "Sword_Attack" if _anim_names.has("sword_attack") else "Attack"
			_play_anim(atk_name, true)
		PlayerState.HURT:   _play_anim("Hit")
		PlayerState.DEAD:   _play_anim("Death")


# ── Combat ─────────────────────────────────────────────────────────────────────
func _start_attack() -> void:
	_stamina -= attack_stamina_cost
	stamina_bar.value = _stamina
	_attack_timer = attack_cooldown
	_attack_hit_done = false
	_combo_count += 1
	_combo_timer = 1.2
	_set_state(PlayerState.ATTACK)
	
	swing_sound.pitch_scale = randf_range(0.9, 1.1)
	swing_sound.play()


func _do_hit_detection() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = attack_range
	query.shape = sphere
	# Cast forward of the player
	var fwd: Vector3 = -transform.basis.z
	query.transform = Transform3D(Basis.IDENTITY, global_position + fwd * (attack_range * 0.6) + Vector3(0, 0.9, 0))
	query.collision_mask = 2  # enemy layer
	query.exclude = [get_rid()]
	var results: Array[Dictionary] = space_state.intersect_shape(query, 8)
	var hit_any: bool = false
	for r in results:
		var body = r["collider"]
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(attack_damage)
			hit_any = true
			print("[Player] HIT %s for %d dmg (combo %d)" % [body.name, int(attack_damage), _combo_count])
	if hit_any:
		hit_sound.pitch_scale = randf_range(0.85, 1.15)
		hit_sound.play()
		_show_hit_label("HIT!")


func _show_hit_label(text: String) -> void:
	hit_label.text = text
	hit_label.modulate.a = 1.0
	hit_label.visible = true


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	_health = max(0.0, _health - amount)
	health_bar.value = _health
	emit_signal("health_changed", _health, max_health)
	damage_flash.modulate.a = 0.7
	_hurt_timer = 0.4
	if _state != PlayerState.ATTACK:
		_set_state(PlayerState.HURT)
	print("[Player] Took %d dmg → %d / %d HP" % [int(amount), int(_health), int(max_health)])
	if _health <= 0.0:
		_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_set_state(PlayerState.DEAD)
	emit_signal("player_died")
	death_panel.visible = true
	print("[Player] DEAD")


# ── Interaction Hint ───────────────────────────────────────────────────────────
func show_interact_hint(text: String = "[E]  Interact") -> void:
	interact_label.text = text
	interact_label.visible = true


func hide_interact_hint() -> void:
	interact_label.visible = false
