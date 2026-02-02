extends CharacterBody2D

# --------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 400
@export var gravity : float = 30

var is_grounded : bool = false

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #

func _process(_delta):
	# Calling functions
	movement()
	player_animations()
	flip_player()
	
# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement():
	# Gravity
	if !is_on_floor():
		velocity.y += gravity
	
	# Move Player
	var inputAxis = Input.get_axis("Left", "Right")
	velocity = Vector2(inputAxis * move_speed, velocity.y)
	move_and_slide()

# Handle Player Animations
func player_animations():
	particle_trails.emitting = false
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)
		else:
			player_sprite.play("Idle")
	else:
		# Keeps the jump animation for when falling off ledges
		player_sprite.play("Jump")

# Flip player sprite based on X velocity
func flip_player():
	if velocity.x < 0: 
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

# Tween Animations
func death_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) 

# --------- SIGNALS ---------- #

func _on_collision_body_entered(_body):
	if _body.is_in_group("Traps"):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
