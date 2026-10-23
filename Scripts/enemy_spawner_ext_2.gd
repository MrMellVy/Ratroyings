extends Node2D

@export var enemy_tscn: PackedScene

var spawn_positions = [651, 677, 700]

func _on_timer_timeout() -> void:
	var name_enemy = enemy_tscn.instantiate()
	self.add_child(name_enemy)
	
	var rand_fixed_y = spawn_positions.pick_random()
	name_enemy.position.y = rand_fixed_y
	name_enemy.position.x = 800
