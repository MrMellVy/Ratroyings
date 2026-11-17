extends State

var cooldown: float = 0.0

func enter() -> void:
	super.enter()
	animation_player.play("walk")

func _physics_process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta
	
	owner.velocity.x = owner.direction_x * owner.SPEED
	if owner.is_on_floor() and player.position.y < owner.position.y - 50:
		owner.velocity.y = owner.JUMP_VELOCITY
	
	super._physics_process(delta)

func transition() -> void:
	var distance_to_player = owner.global_position.distance_to(player.global_position)
	
	if distance_to_player < 75:
		get_parent().change_state("Attack")
		cooldown = 0.0
	
	if distance_to_player > 150 and cooldown <= 0.0:
		var chance = randf()
		if chance < 0.7:
			get_parent().change_state("SpawnMinion")
		else:
			get_parent().change_state("Teleport")
		cooldown = 2.0
		print("rolled", chance)
