extends Area2D
class_name BaseCoin  # This allows other scripts to 'inherit' from this

@export var amplitude := 4
@export var frequency := 5

var time_passed = 0
var initial_position := Vector2.ZERO

func _ready():
	initial_position = position
	# Ensure the coin is in the right group for detection
	add_to_group("Coins")

func _process(delta):
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)

# --- THE TEMPLATE FUNCTION ---
func emit_collection_signal():
	pass # To be overridden by Square, Circle, and Triangle

func _on_body_entered(body):
	if body.is_in_group("Player"):
		emit_collection_signal()
		
		# Standard Visual/Audio polish
		if AudioManager.has_node("coin_pickup_sfx"):
			AudioManager.coin_pickup_sfx.play()
			
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
		await tween.finished
		queue_free()
