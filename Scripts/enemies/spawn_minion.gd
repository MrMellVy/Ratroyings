extends State

@export var minion_node: PackedScene
var can_transition: bool = false

func enter() -> void:
	super.enter()
	owner.velocity = Vector2.ZERO
	animation_player.play("summon")
	await animation_player.animation_finished
	can_transition = true
	
func spawn():
	var current_minions = get_tree().get_nodes_in_group("boss_minions").size()
	if current_minions >= 3:
		print("Max minions reached.")
		return
	var minion = minion_node.instantiate()
	minion.add_to_group("boss_minions")
	
	var offset_x = 40 * owner.direction_x
	minion.position = owner.position + Vector2(offset_x, 21)
	
	get_tree().current_scene.add_child(minion)

	if minion.has_method("start_spawn_animation"):
		minion.start_spawn_animation()

func transition() -> void:
	if can_transition:
		get_parent().change_state("Follow")
		can_transition = false
		
