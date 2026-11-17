extends Node2D
class_name State

@onready var debug = owner.find_child("debug")
@onready var player = get_tree().get_first_node_in_group("player")
@onready var animation_player = owner.find_child("AnimationPlayer")
@onready var animation_player_2 = owner.find_child("AnimationPlayer2")

func _ready() -> void:
	set_physics_process(false)

func enter() -> void:
	set_physics_process(true)

func exit() -> void:
	set_physics_process(false)

func transition() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	transition()
	debug.text = name
