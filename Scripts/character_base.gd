extends CharacterBody3D

## CharacterBase — Modular Base Class for Entities with Health and Animations
## Handles common state like HP, dying, and dynamic animation loading.

@export_group("Stats")
@export var max_health: float = 100.0

var _health: float
var anim_player: AnimationPlayer = null
var _anim_names: Dictionary = {}
var _current_anim: String = ""

signal died(entity: Node3D)

func _ready() -> void:
	_health = max_health

# ── Animation Management ───────────────────────────────────────────────────────

func _find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var result: AnimationPlayer = _find_anim_player(child)
		if result:
			return result
	return null

func _load_external_animations(anim_paths: Array[String]) -> void:
	if not anim_player:
		return
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

func _discover_animations(wanted: Array[String]) -> void:
	if not anim_player:
		return
	var anim_list: PackedStringArray = anim_player.get_animation_list()
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
	print("[%s] Discovered animations: " % name, _anim_names)

func _play_anim(short_name: String, restart: bool = false) -> void:
	if not anim_player:
		return
	var key: String = short_name.to_lower()
	var full: String = _anim_names.get(key, "")
	if full == "":
		# Direct fallback
		if anim_player.has_animation(short_name):
			full = short_name
		else:
			return
	if _current_anim == full and not restart:
		return
	_current_anim = full
	if restart:
		anim_player.stop()
		anim_player.play(full, 0.2)
	else:
		anim_player.play(full, 0.2)


# ── Combat ─────────────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if _health <= 0.0:
		return
	_health -= amount
	print("[%s] Took %d dmg → %d / %d HP" % [name, int(amount), int(_health), int(max_health)])
	_on_take_damage(amount)
	if _health <= 0.0:
		_die()

# Virtual method for subclasses to add hit logic (e.g. state change, UI updates)
func _on_take_damage(amount: float) -> void:
	pass

# Virtual method for subclasses to handle dying (e.g. animation, dropping items)
func _die() -> void:
	emit_signal("died", self)
