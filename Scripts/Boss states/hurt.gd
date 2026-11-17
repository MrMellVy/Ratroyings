extends State

func enter() -> void:
	super.enter()
	owner.velocity = Vector2.ZERO
	owner.disable_damage()
	animation_player.stop()
	animation_player.play("hurt")
	await animation_player.animation_finished
	get_parent().change_state("Follow")
