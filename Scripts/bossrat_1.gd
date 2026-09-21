extends CharacterBody2D

class_name BossRat

const SPEED = 10.0
const JUMP_VELOCITY = -300.0
const GRAVITY = 980.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite = $AnimatedSprite2D
@onready var progress_bar = $UI/ProgressBar
@onready var damageLabelIndicator = $DamageLabelIndicator

var direction_x : float = 1.0
var direction: Vector2

@export var hurt_cooldown: float = 1.0
@export var damage_to_deal: int = 30
@export_range(0.0, 1.0) var stagger_resist: float = 0.7

var can_be_hurt: bool = true
var is_invulnerable: bool = false
var is_dealing_damage: bool = false
var has_dealt_damage: bool = false
var defeat: bool = false

var health: int:
	set(value):
		health = value
		progress_bar.value = value
		if value <= 0:
			defeat = true
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Defeat")

func _ready() -> void:
	add_to_group("enemies")
	var current_level_name = get_tree().current_scene.name
	
	if current_level_name == "Level_2":
		progress_bar.max_value = 500
		health = 500
	elif current_level_name == "Level_3":
		progress_bar.max_value = 750
		health = 750
	else:
		progress_bar.max_value = 350
		health = 350
func _process(_delta: float) -> void:
	direction = player.position - position
	if player.position.x < position.x :
		animated_sprite.flip_h = false
		direction_x = -1.0
	else:
		animated_sprite.flip_h = true
		direction_x = 1.0
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	Global.EnemyDamageAmount = damage_to_deal
	move_and_slide()

func _on_boss_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		var damage = Global.playerDamageAmount
		take_damage(damage)

func enable_damage():
	is_dealing_damage = true
	has_dealt_damage = false
	
func disable_damage():
	is_dealing_damage = false

func take_damage(damage_amount: int):
	if not can_be_hurt or defeat or is_invulnerable:
		return
		
	health -= damage_amount
	damageLabelIndicator.show_damage_label(-damage_amount)
	print("Boss took ", damage_amount, " damage! HP left: ", health)
	if health > 0 and not defeat:
		can_be_hurt = false
		if randf() > stagger_resist:
			find_child("FiniteStateMachine").change_state("Hurt")
		else:
			var possible_counters = ["Attack"]
			var current_level_name = get_tree().current_scene.name
			if current_level_name == "Level_3" or current_level_name == "level_3":
				if randf() < 0.20:
					possible_counters.append("Dash")
			else:
				if randf() < 0.40:
					possible_counters.append("SpawnMinion")
			var random_count = possible_counters.pick_random()
			find_child("FiniteStateMachine").change_state(random_count)
		if get_tree().current_scene.name == "Level_2":
			await get_tree().create_timer(hurt_cooldown).timeout
		can_be_hurt = true
