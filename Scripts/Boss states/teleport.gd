extends State

var can_transition: bool = false
@onready var ray: RayCast2D = owner.get_node("TeleportRay")
@onready var ground_ray: RayCast2D = owner.get_node("GroundRay")

func enter() -> void:
	super.enter()
	owner.velocity = Vector2.ZERO
	animation_player.play("teleport")
	await animation_player.animation_finished
	can_transition = true

func teleport():
	var destination = Vector2(player.position.x + 40, owner.position.y)
	
	ray.global_position = owner.global_position
	ray.target_position = destination - owner.global_position
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		owner.position = destination

	ground_ray.global_position = Vector2(destination.x, destination.y - 100)
	ground_ray.target_position = Vector2.DOWN * 300
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		destination.y = ground_ray.get_collision_point().y
	
	owner.position = destination
	
func transition() -> void:
	if can_transition:
		get_parent().change_state("Follow")
		can_transition = false
