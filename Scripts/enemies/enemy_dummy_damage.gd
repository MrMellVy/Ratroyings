extends CharacterBody2D

class_name TrainingDummy

@export_category("Stats")
@export var health_max: int = 9999
@export var gravity: float = 900.0

var health: int
var taking_damage: bool = false
var hit_by_skill: bool = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	health = health_max
	if animated_sprite_2d.material:
		animated_sprite_2d.material = animated_sprite_2d.material.duplicate()
		animated_sprite_2d.play("idle")

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
		
		velocity.x = 0
		
		move_and_slide()


func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		var damage = Global.playerDamageAmount
		take_damage(damage)
		
		
func take_damage(damage: int) -> void:
	health -= damage
	taking_damage = true
	print ("Dummy took ", damage, " damage. Current health is ", health)
	
	animated_sprite_2d.play("hitted")
	if animation_player and animation_player.has_animation("TakeDamage"):
		animation_player.play("TakeDamage")
	
	if health <= 0:
		health = health_max
		print("Dummy health reset")
		
	await get_tree().create_timer(0.8).timeout
	taking_damage = false
	animated_sprite_2d.play("idle")
