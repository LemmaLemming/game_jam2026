extends Node2D

@onready var player = $Player
@onready var hazard_layer = $Level/Layer1
@onready var spawn_point = $Level/SpawnPoint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Add the layer to the 'Traps' group. 
	# If the Player has an Area2D detector looking for "Traps", this ensures it triggers automatically.
	if hazard_layer:
		hazard_layer.add_to_group("Traps")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(hazard_layer):
		# Iterate through all surfaces the player is currently touching/sliding on
		for i in player.get_slide_collision_count():
			var collision = player.get_slide_collision(i)
			
			# Check if the collision object is our Hazard Layer
			if collision.get_collider() == hazard_layer:
				trigger_restart()

func trigger_restart():
	# Use the player's built-in death logic if available for consistent visuals/audio
	if player.has_method("death_tween"):
		# Simple check to prevent spamming the function while the death animation is already playing
		# (The death animation scales the player down to 0)
		if player.scale.x > 0.9: 
			player.death_tween()
	else:
		# Fallback: Instant teleport if no death script exists
		player.global_position = spawn_point.global_position
