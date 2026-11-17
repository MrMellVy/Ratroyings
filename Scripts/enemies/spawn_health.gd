extends RigidBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	manage_lifespan()
	animation_player.play("float")
	
#For how long the powerups will last, counted with the start_flicker too.
func manage_lifespan() -> void:
	await  get_tree().create_timer(12.0).timeout
	start_flicker()
	await get_tree().create_timer(3.0).timeout
	queue_free()

func start_flicker() -> void:
	var tween = create_tween().set_loops(15)
	tween.tween_property($Sprite2D, "modulate:a", 0.2, 0.1)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)


func _on_area_2d_body_entered(body: Node2D) -> void:
		if body.is_in_group("player"):
			if body.health < body.health_max:
				var heal_amount: int
				if randf() < 0.5:
					heal_amount = 55
					print("Got High Heal! 55 HP")
				else:
					heal_amount = randi_range(45, 35)
					print("Normal Heal! Restored ", heal_amount, " HP.")
				body.heal(heal_amount)
				queue_free()
			else:
				print("HP Still full. Ignored the Pick-up.")
