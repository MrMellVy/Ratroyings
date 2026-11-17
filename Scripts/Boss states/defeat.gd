extends State

func enter() -> void:
	super.enter()
	owner.velocity = Vector2.ZERO
	owner.set_physics_process(false)
	owner.set_process(false)
	
	owner.disable_damage()
	animation_player.stop()
	
	print("boss defeated!")
	var level = owner.get_parent()
	if level.has_method("_on_boss_fight_won"):
		level._on_boss_fight_won()
func  boss_slained():
	print("boss defeated!")
