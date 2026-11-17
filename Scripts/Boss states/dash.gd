extends State

var is_dashing: bool = false
var dash_speed: float = 600.0
var dash_dir: float = 1.0
var is_finished: bool = false

func enter() -> void:
	super.enter()
	owner.velocity = Vector2.ZERO
	owner.is_invulnerable = true
	is_dashing = false
	is_finished = false

	var tween = create_tween().set_loops(3)
	tween.tween_property(owner.animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(owner.animated_sprite, "modulate", Color.WHITE, 0.1)
	await tween.finished

	dash_dir = owner.direction_x
	animation_player.play("dash")
	
	await animation_player.animation_finished
	is_finished = true

func start_dash() -> void:
	is_dashing = true
	owner.enable_damage()

func stop_dash() -> void:
	is_dashing = false
	owner.velocity = Vector2.ZERO
	owner.disable_damage() 

func _physics_process(delta: float) -> void:
	if is_dashing:
		owner.velocity.x = dash_speed * dash_dir
	transition()

func transition() -> void:
	if is_finished:
		get_parent().change_state("Follow")

func exit() -> void:
	super.exit()
	is_dashing = false
	owner.is_invulnerable = false
	owner.disable_damage()
	owner.animated_sprite.modulate = Color.WHITE 
