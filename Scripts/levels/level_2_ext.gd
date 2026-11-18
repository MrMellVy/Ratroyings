extends Node2D

var is_game_over = false

@onready var end_timer: Timer = $EndTimer
@onready var spawner_timer: Timer = $EnemySpawner/Timer
@onready var progress_bar: ProgressBar = $Control/CanvasLayer/ProgressBar

func _ready() -> void:
	end_timer.wait_time = 15.0
	end_timer.one_shot = true
	if not end_timer.timeout.is_connected(_on_end_timer_timeout):
		end_timer.timeout.connect(_on_end_timer_timeout)

	# Initialize progress bar just like BossRat
	progress_bar.max_value = end_timer.wait_time
	progress_bar.value = end_timer.wait_time
	progress_bar.visible = true

	end_timer.start()

	$Control/scoreLabels/ScoreAnim.play("ScoreDown")

	await $Control/scoreLabels/ScoreAnim.animation_finished
	await get_tree().create_timer(1.5).timeout

func _process(_delta: float) -> void:
	if is_game_over or end_timer.is_stopped():
		return

	# Smoothly drain the bar in real time
	progress_bar.value = end_timer.time_left

func reset_value():
	is_game_over = false
	progress_bar.max_value = end_timer.wait_time
	progress_bar.value = end_timer.wait_time
	progress_bar.visible = true

func _on_end_timer_timeout() -> void:
	end_level()

func end_level() -> void:
	if is_game_over:
		return
	is_game_over = true

	# Hide progress bar when timer finishes (mirrors BossRat defeat)
	progress_bar.value = 0
	progress_bar.visible = false

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
	get_tree().quit()
