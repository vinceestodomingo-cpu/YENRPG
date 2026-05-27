extends CharacterBody3D

@export_group("Movement")
@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 10.0
@export var jump_velocity: float = 4.5
@export var rotation_speed: float = 12.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-80)
@export var max_pitch: float = deg_to_rad(80)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_input: Vector2 = Vector2.ZERO

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_input.x -= event.relative.x * mouse_sensitivity
		camera_input.y -= event.relative.y * mouse_sensitivity

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	# Rotate pivot for horizontal look
	rotate_y(camera_input.x)
	# Tilt spring arm for vertical look
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x + camera_input.y, min_pitch, max_pitch)
	
	camera_input = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction relative to camera/player rotation
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		# Smoothly interpolate velocity
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		
		# Rotate visuals to face movement direction
		var target_rotation := atan2(direction.x, direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation - rotation.y, rotation_speed * delta)
	else:
		# Apply friction
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()
