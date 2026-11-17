extends Node2D

var is_game_over = false

@onready var end_timer: Timer = $EndTimer
@onready var spawner_timer: Timer = $EnemySpawner/Timer

func reset_value():
	is_game_over = false

func _on_end_timer_timeout() -> void:
	end_level()

func end_level() -> void:
	if is_game_over:
		return
	is_game_over = true

	# Stop new enemies from spawning.
	spawner_timer.stop()
	end_timer.stop()

	# Stop the background scroll and freeze the player.
	$Parallax2D.autoscroll = Vector2.ZERO
	$Player.set_process(false)

	# Clear any enemies still on screen.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	print("Level ended after %s seconds" % end_timer.wait_time)

