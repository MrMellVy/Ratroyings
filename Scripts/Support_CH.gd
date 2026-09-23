extends CharacterBody2D

@export var player: Player

@export var SPEED: int = 200.0
@export var ACCELARATION: int = 700
@export var FRICTION: int = 800
@export var GRAVITY: float = 980.0

@export_category("Support Combat")
@export var attack_damage: int = 10
@export var skill_damage: int = 15
@export var detection_range: float = 220.0
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 1.5
@export var skill_dash_speed: float = 300.0
@export var skill_dash_time: float = 0.25
@export var skill_radius: float = 90.0
@export_range(0.0, 1.0) var skill_chance: float = 0.3
@export_range(0.0, 1.0) var attack_chance: float = 0.2

@export_category("Debug")
@export var disable_enemy_detection := false

@export var Anim_sprite: AnimatedSprite2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

var target_enemy: CharacterBody2D = null
var attack_cooldown_timer: float = 0.0
var is_attacking: bool = false
var is_using_skill: bool = false
var retarget_time: float = 0.0
var skill_dash_dir: float = 0.0
var is_skill_dashing: bool = false
const RETARGET_DELAY: float = 0.2

func _ready() -> void:
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 6.0
	navigation_agent_2d.path_max_distance = 200.0
	navigation_agent_2d.avoidance_enabled = false
	
func _physics_process(delta: float) -> void:
	if player == null and Global.playerBody != null:
		player = Global.playerBody
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	attack_cooldown_timer -= delta
	if attack_cooldown_timer < 0.0:
		attack_cooldown_timer = 0.0
	
	retarget_time -= delta
	if retarget_time < 0.0:
		retarget_time = 0.0
	
	if player == null or not is_instance_valid(player) or not Global.playerAlive:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		play_anim("idle")
		move_and_slide()
		return
		
	if disable_enemy_detection:
		target_enemy = null
	else:
		if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.defeat:
			find_target_enemy()
			retarget_time = RETARGET_DELAY
		elif retarget_time <= 0.0:
			find_target_enemy()
			retarget_time = RETARGET_DELAY
	
	if is_attacking:
		if is_skill_dashing:
			velocity.x = skill_dash_dir * skill_dash_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		return
	
	if target_enemy != null:
		var distance_to_enemy: float = global_position.distance_to(target_enemy.global_position)
		navigation_agent_2d.target_position = target_enemy.global_position
		
		if abs(target_enemy.global_position.x - global_position.x) > 6.0:
			change_direction(sign(target_enemy.global_position.x - global_position.x))
		
		if distance_to_enemy <= attack_range:
			if attack_cooldown_timer <= 0.0:
				velocity.x = move_toward(velocity.x, 0.0,FRICTION * delta)
				play_anim("idle")
				try_attack()
				move_and_slide()
				return
			else:
				velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		else:
			follow_navigation(delta)
	else:
		var follow_pos := player.global_position + Vector2(30,0)
		navigation_agent_2d.target_position = follow_pos
		if global_position.distance_to(follow_pos) > 16.0:
			follow_navigation(delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			
	update_movement_animation()
	move_and_slide()

func follow_navigation(delta: float) -> void:
	var target_x := navigation_agent_2d.target_position.x
	var dist_x = abs(target_x - global_position.x)

	if dist_x > 8.0:
		var dir_x = sign(target_x - global_position.x)
		change_direction(dir_x)
		velocity.x = move_toward(velocity.x, dir_x * SPEED, ACCELARATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

func find_target_enemy() -> void:
	target_enemy = null
	var closet_distance: float = detection_range
	
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		
		if not node is CharacterBody2D:
			continue
		
		if not node.has_method("take_damage"):
			continue
		
		if "defeat" in node and node.defeat:
			continue
		
		var enemy_node: CharacterBody2D = node
		var distance_to_enemy: float = global_position.distance_to(enemy_node.global_position)
		
		if distance_to_enemy <= closet_distance:
			closet_distance = distance_to_enemy
			target_enemy = enemy_node
			
func update_movement_animation() -> void:
	if is_attacking or is_using_skill:
		return
	if abs(velocity.x) > 10.0:
		play_anim("run")
	else:
		play_anim("idle")

func play_anim(anim_name: String) -> void:
	if Anim_sprite.sprite_frames == null:
		return
	
	if not Anim_sprite.sprite_frames.has_animation(anim_name):
		return
		
	if Anim_sprite.animation != anim_name:
		Anim_sprite.play(anim_name)
		
func play_anim_attack(anim_name: String) -> void:
	if Anim_sprite.sprite_frames == null:
		return
	
	if not Anim_sprite.sprite_frames.has_animation(anim_name):
		return
		
	Anim_sprite.play(anim_name)

func try_attack() -> void:
	if disable_enemy_detection:
		return
	if is_attacking:
		return
		
	if attack_cooldown_timer > 0.0:
		return
	
	if target_enemy == null:
		return
		
	if not is_valid_target(target_enemy):
		return
	
	if randf() > attack_chance:
		attack_cooldown_timer = 0.4
		return
	
	is_attacking = true
	
	var attack_target: CharacterBody2D = target_enemy
	
	if abs(attack_target.global_position.x -global_position.x) > 5.0:
		change_direction(sign(attack_target.global_position.x - global_position.x))
	
	if randf() < skill_chance:
		await  use_skill_a(attack_target)
	else:
		await  normal_attack(attack_target)
	
	is_attacking = false
	attack_cooldown_timer = attack_cooldown
		
func normal_attack(target: CharacterBody2D) -> void:
	print("Support Char Normal Attack start.")
	#modulate = Color.GREEN
	play_anim_attack("atk1")
	await  get_tree().create_timer(0.2).timeout
	
	if is_valid_target(target):
		target.take_damage(attack_damage)

func use_skill_a(target: CharacterBody2D) -> void:
	print("Support Char Skill start.")
	
	is_using_skill = true
	modulate = Color.YELLOW
	play_anim_attack("skill_a")
	
	if not is_inside_tree(): return
	await get_tree().create_timer(0.35).timeout
	
	if not is_inside_tree(): return
	
	if not is_valid_target(target):
		is_using_skill = false
		modulate = Color.WHITE
		return
	var dir: float = sign(target.global_position.x - global_position.x)
	
	if dir == 0.0:
		if Anim_sprite.flip_h:
			dir = -1.0
		else:
			dir = 1.0
	change_direction(dir)
	
	is_skill_dashing = true
	skill_dash_dir = dir
	
	var hit_count: int = 3
	
	for i in range(hit_count):
		var enemies := get_enemies_in_range(skill_radius)
		print("Skill hit: ", enemies.size())
		
		for enemy in enemies:
			if is_valid_target(enemy):
				enemy.take_damage(skill_damage)
		if not is_inside_tree(): return
		await get_tree().create_timer(0.15).timeout
		
		if not is_inside_tree(): return
		
		is_skill_dashing = false
		skill_dash_dir = 0.0
		velocity.x = 0.0
		is_using_skill = false
		modulate = Color.WHITE

func debug_force_skill_a() -> void:
	if is_attacking or is_using_skill:
		return

	if target_enemy == null or not is_valid_target(target_enemy):
		find_target_enemy()

	if target_enemy == null or not is_valid_target(target_enemy):
		print("Support cheat: no enemy for skill_a")
		return

	attack_cooldown_timer = 0.0
	is_attacking = true

	await use_skill_a(target_enemy)

	is_attacking = false
	attack_cooldown_timer = attack_cooldown

func get_enemies_in_range(radius: float) -> Array:
	var enemies: Array = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy:= node as CharacterBody2D
		
		if enemy == null:
			continue
		
		if not is_instance_valid(enemy) or enemy.defeat:
			continue
		
		if global_position.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)
	return enemies

func is_valid_target(target: CharacterBody2D) -> bool:
	if not is_instance_valid(target):
		return false
	if not target.has_method("take_damage"):
		return false
	if "defeat" in target and target.defeat:
		return false
	return true

func change_direction(direction: float) -> void:
	if abs(direction) < 0.1:
		return
		
	if direction < 0.0:
		Anim_sprite.flip_h = true
	else:
		Anim_sprite.flip_h = false

#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed and not event.echo:
		#if event.keycode == KEY_I:
			#disable_enemy_detection = not disable_enemy_detection
			#if disable_enemy_detection:
				#target_enemy = null
			#
			#print("SpChar dect: ", disable_enemy_detection)
		#elif  event.keycode == KEY_K:
			#debug_force_skill_a()
