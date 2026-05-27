extends CharacterBody3D

## SkeletonEnemy — Simple state-machine enemy AI
## States: IDLE → PATROL → CHASE → ATTACK → DEAD
## Group: "Enemy"
## Detects player via Area3D (DetectionZone) and attack range

# ── Stats ──────────────────────────────────────────────────────────────────────
@export_group("Stats")
@export var max_health: float = 60.0
@export var move_speed: float = 2.5
@export var chase_speed: float = 4.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 1.4
@export var detection_range: float = 8.0
@export var patrol_radius: float = 3.0

# ── State Machine ──────────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }
var _state: State = State.IDLE

# ── Runtime ────────────────────────────────────────────────────────────────────
var _health: float
var _player: CharacterBody3D = null
var _patrol_target: Vector3
var _patrol_origin: Vector3
var _attack_timer: float = 0.0
var _idle_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ── Node References ────────────────────────────────────────────────────────────
@onready var detection_area: Area3D = $DetectionZone

# Resolved dynamically in _ready — GLB import path varies
var anim_player: AnimationPlayer = null
var _anim_names: Dictionary = {}
var _current_anim: String = ""

# ── Signals ────────────────────────────────────────────────────────────────────
signal died(enemy: Node3D)

# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("Enemy")
	_health = max_health
	_patrol_origin = global_position
	_idle_timer = randf_range(0.5, 2.0)  # stagger start so not all move at once

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	# Find AnimationPlayer anywhere in the Model child
	var model: Node3D = get_node_or_null("Model")
	if model:
		anim_player = _find_anim_player(model)
	if not anim_player:
		anim_player = _find_anim_player(self)

	if anim_player:
		print("[Skeleton] AnimationPlayer found at: ", anim_player.get_path())
		_discover_animations()
	else:
		push_warning("[Skeleton] No AnimationPlayer found — anims disabled.")

	_set_anim("Idle")
	print("[Skeleton] Ready at %s" % str(global_position))


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
	print("[Skeleton] Discovered anims: ", _anim_names)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Attack cooldown
	_attack_timer = max(0.0, _attack_timer - delta)

	match _state:
		State.IDLE:
			_tick_idle(delta)
		State.PATROL:
			_tick_patrol(delta)
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			_tick_attack(delta)

	move_and_slide()


# ── State Ticks ────────────────────────────────────────────────────────────────
func _tick_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_pick_patrol_target()
		_change_state(State.PATROL)


func _tick_patrol(delta: float) -> void:
	var dist: float = global_position.distance_to(_patrol_target)
	if dist < 0.5:
		_idle_timer = randf_range(1.5, 3.5)
		_change_state(State.IDLE)
		return
	_move_toward(_patrol_target, move_speed, delta)


func _tick_chase(delta: float) -> void:
	if _player == null:
		_change_state(State.PATROL)
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= attack_range:
		_change_state(State.ATTACK)
	elif dist > detection_range * 1.6:
		_player = null
		_change_state(State.PATROL)
	else:
		_move_toward(_player.global_position, chase_speed, delta)


func _tick_attack(delta: float) -> void:
	if _player == null:
		_change_state(State.PATROL)
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist > attack_range * 1.25:
		_change_state(State.CHASE)
		return

	# Face player
	var dir: Vector3 = (_player.global_position - global_position)
	dir.y = 0
	if dir.length_squared() > 0.01:
		var tb: Basis = Basis.looking_at(dir.normalized(), Vector3.UP)
		transform.basis = transform.basis.slerp(tb, 14.0 * delta)

	velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0, 10.0 * delta)

	if _attack_timer <= 0.0:
		_do_attack()


# ── Actions ────────────────────────────────────────────────────────────────────
func _move_toward(target: Vector3, spd: float, delta: float) -> void:
	var dir: Vector3 = (target - global_position)
	dir.y = 0
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()
	velocity.x = lerp(velocity.x, dir.x * spd, 12.0 * delta)
	velocity.z = lerp(velocity.z, dir.z * spd, 12.0 * delta)
	var tb: Basis = Basis.looking_at(dir, Vector3.UP)
	transform.basis = transform.basis.slerp(tb, 10.0 * delta)


func _do_attack() -> void:
	_attack_timer = attack_cooldown
	_set_anim("Attack", true)
	# Delay damage by 0.4s to align with swing
	get_tree().create_timer(0.4).timeout.connect(func():
		if _state == State.ATTACK and _player and is_instance_valid(_player):
			var dist: float = global_position.distance_to(_player.global_position)
			if dist <= attack_range * 1.3 and _player.has_method("take_damage"):
				_player.take_damage(attack_damage)
				print("[Skeleton] HIT player for %d" % int(attack_damage))
	)


func take_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	_health -= amount
	print("[Skeleton] Took %d dmg → %d / %d HP" % [int(amount), int(_health), int(max_health)])
	_change_state(State.CHASE)
	if _health <= 0.0:
		_die()


func _die() -> void:
	_change_state(State.DEAD)
	print("[Skeleton] Defeated!")
	emit_signal("died", self)
	_set_anim("Death", true)
	await get_tree().create_timer(2.2).timeout
	queue_free()


# ── State Change ───────────────────────────────────────────────────────────────
func _change_state(new_state: State) -> void:
	if _state == new_state or _state == State.DEAD:
		return
	_state = new_state
	match new_state:
		State.IDLE:   _set_anim("Idle")
		State.PATROL: _set_anim("Walk")
		State.CHASE:  _set_anim("Run")
		State.ATTACK: pass  # set in _do_attack with restart
		State.DEAD:   _set_anim("Death", true)


func _pick_patrol_target() -> void:
	var angle: float = randf() * TAU
	var radius: float = randf_range(1.0, patrol_radius)
	_patrol_target = _patrol_origin + Vector3(cos(angle) * radius, 0, sin(angle) * radius)


# ── Detection ──────────────────────────────────────────────────────────────────
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and _state != State.DEAD:
		_player = body as CharacterBody3D
		_change_state(State.CHASE)
		print("[Skeleton] Player spotted!")


func _on_body_exited(body: Node3D) -> void:
	pass  # keep chasing outside detection radius (handled in tick_chase)


# ── Animation Helper ───────────────────────────────────────────────────────────
func _set_anim(short_name: String, restart: bool = false) -> void:
	if not anim_player:
		return
	var key: String = short_name.to_lower()
	var full: String = _anim_names.get(key, "")
	if full == "":
		# Direct fallback
		if anim_player.has_animation(short_name):
			full = short_name
		else:
			# Generic fallback: play any available anim if nothing running
			if anim_player.current_animation == "" and anim_player.get_animation_list().size() > 0:
				anim_player.play(anim_player.get_animation_list()[0])
			return
	if _current_anim == full and not restart:
		return
	_current_anim = full
	anim_player.play(full)
