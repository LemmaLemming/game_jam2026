extends CharacterBody2D

# --------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 400
@export var gravity : float = 30
@export var jump_velocity : float = -600.0 

# Ability Unlocks
@export var is_circle_collected := false
@export var is_square_collected := false
@export var is_triangle_collected := false

# Gravity Ability Variables
var is_gravity_flipped := false

# State Management
enum MovementMode { DEFAULT, CIRCLE, SQUARE, TRIANGLE }
var current_mode = MovementMode.DEFAULT

@onready var player_sprite = $AnimatedSprite2D
@onready var player_sprite_overlay = $AnimatedSprite2DO
@onready var player_sprite_transform = $AnimatedSprite2DT
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #

func _ready():
	# Ensure the transform sprite is hidden on game start
	player_sprite_transform.visible = false
	player_sprite_overlay.visible = false

# Changed to _physics_process for consistent movement behavior
func _physics_process(_delta):
	# 1. Handle Input Toggles
	check_ability_toggles()
	
	# 2. Run Movement based on current state
	match current_mode:
		MovementMode.DEFAULT:
			movement()
		MovementMode.CIRCLE:
			attempt_circle_physics()
		MovementMode.SQUARE:
			attempt_square_physics()
		MovementMode.TRIANGLE:
			attempt_triangle_physics()
	
	# 3. Visuals
	player_animations()
	flip_player()

# --------- CUSTOM FUNCTIONS ---------- #

func check_ability_toggles():
	if Input.is_action_just_pressed("ability1"):
		default_movement()
	elif Input.is_action_just_pressed("ability2"):
		attempt_circle()
	elif Input.is_action_just_pressed("ability3"):
		attempt_square()
	elif Input.is_action_just_pressed("ability4"):
		attempt_triangle()

func movement():
	# Regular Gravity
	up_direction = Vector2.UP
	if !is_on_floor():
		velocity.y += gravity
	else:
		velocity.y = push_error_correction(velocity.y)
	
	var inputAxis = Input.get_axis("Left", "Right")
	velocity.x = inputAxis * move_speed
	
	move_and_slide()

# --- Ability Physics ---

func attempt_circle_physics():
	if Input.is_action_just_pressed("Action"):
		toggle_gravity()
	
	# When up_direction is managed correctly, is_on_floor() always returns 
	# true if we are standing on the surface opposing gravity.
	var grounded = is_on_floor()
	
	if !grounded:
		var current_gravity = -gravity if is_gravity_flipped else gravity
		velocity.y += current_gravity
	else:
		velocity.y = -2 if is_gravity_flipped else 2
		
	# Disable horizontal movement in Circle mode
	velocity.x = 0
	
	# Ensure sprite is upright (rotation 0) since we rely on animations for orientation
	# and might be coming from Square mode (which rotates the sprite).
	if player_sprite.rotation != 0:
		var new_rotation = rotate_toward(player_sprite.rotation, 0.0, 0.1)
		player_sprite.rotation = new_rotation
		player_sprite_overlay.rotation = new_rotation
		player_sprite_transform.rotation = new_rotation
	
	up_direction = Vector2.DOWN if is_gravity_flipped else Vector2.UP
	move_and_slide()

func toggle_gravity():
	# Purely toggle the state. 
	# Visual orientation is now handled by the 'circle - ceiling' vs 'circle - floor' animations.
	is_gravity_flipped = !is_gravity_flipped

func attempt_square_physics():
	# SQUARE: Unified Sticking Logic
	up_direction = Vector2.UP
	
	var is_sticking = false
	var surface_normal = Vector2.ZERO
	
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			surface_normal = collision.get_normal()
			is_sticking = true
			break 
	
	if is_sticking:
		# ROTATION: Align feet to surface
		var target_angle = surface_normal.angle() + PI/2
		
		# Smoothly rotate player, overlay, and transform
		var new_rotation = rotate_toward(player_sprite.rotation, target_angle, 0.2)
		player_sprite.rotation = new_rotation
		player_sprite_overlay.rotation = new_rotation
		player_sprite_transform.rotation = new_rotation
		
		# MOVEMENT: 4-Way movement
		var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
		velocity = input_dir * move_speed
		
		# STICKING FORCE
		velocity -= surface_normal * 100
		
	else:
		# Air State
		velocity.y += gravity
		
		# Rotate back to upright
		var new_rotation = rotate_toward(player_sprite.rotation, 0.0, 0.1)
		player_sprite.rotation = new_rotation
		player_sprite_overlay.rotation = new_rotation
		player_sprite_transform.rotation = new_rotation
		
		var x_input = Input.get_axis("Left", "Right")
		velocity.x = x_input * move_speed

	move_and_slide()

func attempt_triangle_physics():
	# TRIANGLE: Zero Gravity / Hover Mode
	up_direction = Vector2.UP
	velocity.y = 0
	
	var inputAxis = Input.get_axis("Left", "Right")
	velocity.x = inputAxis * move_speed
	
	# Visuals: Rotate back to upright
	if player_sprite.rotation != 0:
		var new_rotation = rotate_toward(player_sprite.rotation, 0.0, 0.1)
		player_sprite.rotation = new_rotation
		player_sprite_overlay.rotation = new_rotation
		player_sprite_transform.rotation = new_rotation
	
	move_and_slide()

func push_error_correction(vel_y):
	return min(vel_y, 10) 

# --- Toggle Logic ---

func trigger_transform():
	# Use the dedicated transform sprite
	player_sprite_transform.visible = true
	player_sprite_transform.frame = 0
	player_sprite_transform.play("transform")
	
	# Await finish to hide it - this is non-blocking for the caller
	await player_sprite_transform.animation_finished
	player_sprite_transform.visible = false

func default_movement():
	if current_mode != MovementMode.DEFAULT:
		if is_gravity_flipped:
			toggle_gravity()
		
		# Reset rotations for all sprites
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(player_sprite, "rotation", 0.0, 0.1)
		tween.tween_property(player_sprite_overlay, "rotation", 0.0, 0.1)
		tween.tween_property(player_sprite_transform, "rotation", 0.0, 0.1)
		
		trigger_transform()
		current_mode = MovementMode.DEFAULT
		print("Mode: Default")

func attempt_circle():
	if is_circle_collected:
		if current_mode != MovementMode.CIRCLE:
			trigger_transform()
			current_mode = MovementMode.CIRCLE
			print("Mode: Circle")
	else:
		print("Circle Locked")

func attempt_square():
	if is_square_collected:
		if current_mode != MovementMode.SQUARE:
			# Reset gravity flip flag for square mode
			is_gravity_flipped = false 
			trigger_transform()
			current_mode = MovementMode.SQUARE
			print("Mode: Square")
	else:
		print("Square Locked")

func attempt_triangle():
	if is_triangle_collected:
		if current_mode != MovementMode.TRIANGLE:
			is_gravity_flipped = false
			trigger_transform()
			current_mode = MovementMode.TRIANGLE
			print("Mode: Triangle")
	else:
		print("Triangle Locked")

# --- Visuals & Tweens ---

func player_animations():
	# 1. Base Player Animations
	particle_trails.emitting = false
	
	var grounded = false
	if current_mode == MovementMode.CIRCLE:
		# Since we flip up_direction, is_on_floor() is true for both 
		# "Standing on Floor" (Normal) and "Standing on Ceiling" (Flipped)
		grounded = is_on_floor()
	elif current_mode == MovementMode.SQUARE:
		grounded = get_slide_collision_count() > 0
	else:
		grounded = is_on_floor()
	
	if grounded:
		if velocity.length() > 20:
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)
		else:
			player_sprite.play("Idle")
	else:
		player_sprite.play("Jump")

	# 2. Overlay Animations
	
	if current_mode == MovementMode.DEFAULT:
		player_sprite_overlay.visible = false
	else:
		player_sprite_overlay.visible = true
		
		var overlay_anim_name = ""
		
		match current_mode:
			MovementMode.CIRCLE:
				if grounded:
					overlay_anim_name = "circle - ceiling" if is_gravity_flipped else "circle - floor"
				else:
					# Adjust 'moving up' logic based on gravity orientation
					# If gravity is flipped, "down" (positive Y) is technically "up" relative to the player
					# velocity.y > 0 means moving "down" in world space (falling normally)
					# velocity.y < 0 means moving "up" in world space (jumping normally)
					
					var is_falling_to_feet = (velocity.y > 0) if !is_gravity_flipped else (velocity.y < 0)
					
					if is_falling_to_feet:
						overlay_anim_name = "circle - inairmovingdown"
					else:
						overlay_anim_name = "circle - inairmovingup"
						
			MovementMode.SQUARE:
				# Uses "square - all" but rotates based on physics logic in attempt_square_physics
				overlay_anim_name = "square - all"
				
			MovementMode.TRIANGLE:
				overlay_anim_name = "triangle - all"
		
		# Only play if the animation has changed to prevent resetting the frame index each tick
		if overlay_anim_name != "" and player_sprite_overlay.animation != overlay_anim_name:
			player_sprite_overlay.play(overlay_anim_name)

func flip_player():
	# Don't flip horizontally if the sprite is rotated sideways (climbing walls)
	var is_sideways = abs(sin(player_sprite.rotation)) > 0.5
	if current_mode == MovementMode.SQUARE and is_sideways:
		return
		
	if velocity.x < 0: 
		player_sprite.flip_h = true
		player_sprite_overlay.flip_h = true
		player_sprite_transform.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false
		player_sprite_overlay.flip_h = false
		player_sprite_transform.flip_h = false

func death_tween():
	if is_gravity_flipped:
		toggle_gravity()
	player_sprite.rotation = 0
	player_sprite_overlay.rotation = 0
	player_sprite_transform.rotation = 0
		
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	# AudioManager.respawn_sfx.play() 
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) 

# --------- SIGNAL RECEIVERS ---------- #

func _on_circle_collected():
	is_circle_collected = true
	print("Circle Unlocked!")

func _on_square_collected():
	is_square_collected = true
	print("Square Unlocked!")

func _on_triangle_collected():
	is_triangle_collected = true
	print("Triangle Unlocked!")

func _on_collision_body_entered(_body):
	if _body.is_in_group("Traps"):
		# AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
