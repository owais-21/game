extends CharacterBody2D

# Movement parameters
@export var walk_speed := 150.0
@export var run_speed := 300.0
@export var acceleration := 20.0
@export var friction := 10.0
@export var air_control := 5.0
@export var gravity := 980.0
@export var max_fall_speed := 600.0

# Jump parameters
@export var jump_velocity := -320.0
@export var double_jump_velocity := -300.0
@export var max_jumps := 2
@export var jump_buffer_time := 0.2
@export var coyote_time := 0.2

# Dash parameters
@export var dash_speed := 600.0
@export var dash_time := 0.2
@export var dash_cooldown := 0.5

# Wall movement
@export var wall_jump_velocity := Vector2(-200, -400)
@export var wall_slide_speed := 150.0

# Ledge grabbing
@export var ledge_grab_offset := Vector2(10, -20)
@export var ledge_climb_time := 0.3
var is_hanging := false
var ledge_position := Vector2()

# Ground Pound
@export var ground_pound_speed := 800.0

# States
var jumps_left := max_jumps
var is_dashing := false
var can_dash := true
var dash_timer := 0.0
var jump_buffer_timer := 0.0
var coyote_timer := 0.0
var is_ground_pounding := false

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor() and not is_dashing and not is_hanging:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

	# Handle ledge grabbing
	if not is_on_floor() and not is_dashing and not is_hanging:
		check_ledge_grab()

	if is_hanging:
		if Input.is_action_just_pressed("jump"):
			climb_ledge()
		elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
			drop_ledge()
		return

	# Handle movement
	var input_direction := Input.get_axis("move_left", "move_right")
	var target_speed := walk_speed if Input.is_action_pressed("crouch") else run_speed
	if input_direction != 0:
		var accel := acceleration if is_on_floor() else air_control
		velocity.x = lerp(velocity.x, input_direction * target_speed, accel * delta)
	else:
		var fric := friction if is_on_floor() else air_control
		velocity.x = lerp(velocity.x, 0.0, fric * delta)

	# Handle jumping
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0:
			jump()
			jump_buffer_timer = 0
		elif jumps_left > 0:
			jump(true)
			jump_buffer_timer = 0

	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer -= delta

	# Handle dash
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			stop_dash()

	# Ground Pound
	if Input.is_action_just_pressed("ground_pound") and not is_on_floor():
		is_ground_pounding = true
		velocity.y = ground_pound_speed

	if is_ground_pounding and is_on_floor():
		is_ground_pounding = false

	# Apply velocity
	move_and_slide()

func jump(is_double_jump := false):
	if is_double_jump and jumps_left > 0:
		velocity.y = double_jump_velocity
		jumps_left -= 1
	else:
		velocity.y = jump_velocity
	coyote_timer = 0

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = dash_time

	# Get the dash direction from input
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Default dash to last known movement direction if no input
	if input_vector == Vector2.ZERO:
		input_vector = Vector2.RIGHT if velocity.x >= 0 else Vector2.LEFT

	# Normalize to maintain constant dash speed
	input_vector = input_vector.normalized()
	velocity = input_vector * dash_speed

	# Check for immediate collision
	var collision = move_and_collide(velocity * get_physics_process_delta_time())
	if collision:
		stop_dash()

func stop_dash():
	is_dashing = false
	
	# Retain some horizontal momentum after dashing in midair
	if not is_on_floor():
		velocity.x *= 0.5  

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# ----------- Ledge Grabbing Functions -----------
func check_ledge_grab():
	var ledge_check_position = position + Vector2(ledge_grab_offset.x * sign(velocity.x), ledge_grab_offset.y)
	var ledge_space_check = ledge_check_position + Vector2(0, -10)

	if is_on_wall() and not is_on_floor():
		if not test_move(transform, ledge_check_position - position) and test_move(transform, ledge_space_check - position):
			grab_ledge(ledge_check_position)

func grab_ledge(ledge_pos):
	is_hanging = true
	velocity = Vector2.ZERO
	position = ledge_pos

func climb_ledge():
	is_hanging = false
	position += Vector2(0, -20)
	await get_tree().create_timer(ledge_climb_time).timeout

func drop_ledge():
	is_hanging = false
	velocity.y = jump_velocity * 0.5
