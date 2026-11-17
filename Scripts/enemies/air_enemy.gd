extends CharacterBody2D

class_name EnemyAir

const speed = 30
var dir: Vector2

var health = 50
var health_max = 50
var health_min = 0

var defeat = false
var taking_damage = false
var is_roaming: bool

var damage_to_deal = 10
var is_dealing_damage: bool = false
var has_dealt_damage: bool = false

var player_in_area = false
var can_attack: bool = true
var is_attacking: bool = false

var is_off_screen: bool = false
var off_screen_timer: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var is_enemyair_chase: bool
@onready var collision_polygon_2d: CollisionShape2D = $"../FlyzoneAirEmy/CollisionPolygon2D"
@onready var anim_play_ae: AnimationPlayer = $AnimPlayAE
@onready var damage_label_indicator = $DamageLabelIndicator

var player: CharacterBody2D

func _ready() -> void:
	add_to_group("enemies")
	if animated_sprite_2d.material:
		animated_sprite_2d.material = animated_sprite_2d.material.duplicate()


func _process(delta: float) -> void:
	if defeat: return
	
	if is_off_screen:
		off_screen_timer += delta
		if off_screen_timer >= 30.0:
			print("the air_enemy despawned.")
			health = 0
			defeat = true
			handle_defeat_sequence()
			return
	
	Global.EnemyAirDamageAmount = damage_to_deal
	Global.EnemyAirDamageZone = $AEDamageZone
	
	if player_in_area and can_attack and !defeat and !taking_damage and !is_attacking and Global.playerAlive and not Global.enemies_passive:
		attack_sequence()
	
	move(delta)
	handle_animation()
	
func move(delta):
	if defeat: 
		return
	
	player = Global.playerBody
	is_roaming = true
	
	var has_player: bool = player != null and is_instance_valid(player)
	var can_chase: bool = has_player and Global.playerAlive and not Global.enemies_passive and is_enemyair_chase
	
	if is_attacking:
		velocity = Vector2.ZERO
		
	elif taking_damage:
		if has_player:
			var knockback_dir = position.direction_to(player.position) * -50
			velocity = knockback_dir
		else:
			velocity = Vector2.ZERO
	elif can_chase:
		velocity = position.direction_to(player.position) * speed
		if velocity.x != 0:
			dir.x = sign(velocity.x)
	else:
		velocity += dir * speed * delta
	move_and_slide()
	
func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 0.8])
	if !is_enemyair_chase:
		dir = choose([Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN])

func handle_animation():
	if defeat: return
	
	elif taking_damage and !defeat:
		anim_play_ae.play("hitted")
		await anim_play_ae.animation_finished
		taking_damage = false
	elif is_attacking:
		animated_sprite_2d.play("attack")
	else:
		animated_sprite_2d.play("Idlefly")
	if dir.x == -1:
		animated_sprite_2d.flip_h = true
	elif dir.x == 1:
		animated_sprite_2d.flip_h = false
			
func attack_sequence():
	can_attack = false
	is_attacking = true
	is_dealing_damage = false
	has_dealt_damage = false
	
	await get_tree().create_timer(0.4).timeout
	
	if defeat or taking_damage or Global.enemies_passive:
		is_attacking = false
		is_dealing_damage = false
		can_attack = true
		return
	
	is_dealing_damage = true
	await  animated_sprite_2d.animation_finished
	
	is_dealing_damage = false
	is_attacking = false
	
	await get_tree().create_timer(1.5).timeout
	can_attack = true

func choose(array):
	array.shuffle()
	return array.front()


func _on_ae_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		var damage = Global.playerDamageAmount
		take_damage(damage)
		
func take_damage(damage):
	if defeat: return
	
	health -= damage
	taking_damage = true
	damage_label_indicator.show_damage_label(-damage)
	if health <= 0:
		health = 0
		defeat = true
		handle_defeat_sequence()
	else:
		await get_tree().create_timer(0.8).timeout
		taking_damage = false
	print(str(self), "current health: ", health)

func handle_defeat_sequence():
	is_roaming = false
	animated_sprite_2d.play("defeat")
	await get_tree().create_timer(1.0).timeout
	velocity = Vector2.ZERO
	handle_defeat()

func handle_defeat():
	self.queue_free()
	Global.current_score += 250

func _on_ae_damage_zone_area_exited(area: Area2D) -> void:
	if area == Global.playerHitbox:
		has_dealt_damage = false
		player_in_area = false

func _on_ae_damage_zone_area_entered(area: Area2D) -> void:
	if area == Global.playerHitbox:
		player_in_area = true


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	is_off_screen = false
	off_screen_timer = 0.0

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	is_off_screen = true
