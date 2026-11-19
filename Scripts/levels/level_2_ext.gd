extends Node2D

var is_game_over: bool = false

@export var max_health: int = 4
@export var score_per_second: float = 10.0
@export var multiplier_threshold: float = 5.0
@export var bgm_name: String = "Battle Encounter"
@export_file("*.tscn") var next_scene_path: String = "res://Scenes/Cutscene/cutscene_4.tscn"

var starting_score: int = 0
var run_score: float = 0.0
var survival_streak: float = 0.0
var score_multiplier: int = 1

@onready var end_timer: Timer = $EndTimer
@onready var spawner_timer: Timer = $EnemySpawner/Timer
@onready var progress_bar: ProgressBar = $Control/CanvasLayer/ProgressBar
@onready var warning_label: Label = $Control/CanvasLayer/WarningLabel

var car_health: int = 4:
	set(value):
		car_health = clampi(value, 0, max_health)
		if is_instance_valid(progress_bar):
			progress_bar.value = car_health
		if car_health <= 0 and not is_game_over:
			trigger_game_over()

func _ready() -> void:
	Global.gameStarted = true
	Global.playerAlive = true
	Global.playerBody = null

	# Stop enemies from spawning during the 5-second warning
	spawner_timer.stop()

	BgmManager.play_BGM(bgm_name)

	if Global.is_continuing:
		Global.current_score = Savedata.score
		Global.is_continuing = false

	starting_score = Global.current_score
	run_score = 0.0
	survival_streak = 0.0
	score_multiplier = 1

	progress_bar.max_value = max_health
	car_health = max_health
	progress_bar.visible = true

	autosave_checkpoint()

	end_timer.process_mode = Node.PROCESS_MODE_INHERIT
	end_timer.wait_time = 15.0
	end_timer.one_shot = true
	if not end_timer.timeout.is_connected(_on_end_timer_timeout):
		end_timer.timeout.connect(_on_end_timer_timeout)

	$Control/scoreLabels/ScoreAnim.play("ScoreDown")

	# Flicker "DODGE THE RAT!" 3 times over 5 seconds before starting the wave
	await show_intro_warning()

	if not is_game_over:
		spawner_timer.start()
		end_timer.start()

func show_intro_warning() -> void:
	warning_label.visible = true
	warning_label.modulate.a = 0.0

	# 3 flickers across 5.0 seconds (6 half-cycles of ~0.833s each)
	var half_cycle: float = 5.0 / 6.0
	var flicker_tween := create_tween().set_loops(3)
	flicker_tween.tween_property(warning_label, "modulate:a", 1.0, half_cycle)
	flicker_tween.tween_property(warning_label, "modulate:a", 0.0, half_cycle)

	await flicker_tween.finished
	warning_label.visible = false

func _process(delta: float) -> void:
	if is_game_over or end_timer.is_stopped():
		return

	survival_streak += delta
	if survival_streak >= multiplier_threshold and score_multiplier == 1:
		score_multiplier = 2
		print("5s survived! 2x Score Multiplier active!")

	run_score += score_per_second * score_multiplier * delta
	Global.current_score = starting_score + roundi(run_score)

	if has_node("Control/scoreLabels/currentscoreLabel"):
		$Control/scoreLabels/currentscoreLabel.text = str(Global.current_score)

func take_car_damage() -> void:
	if is_game_over:
		return

	run_score = 0.0
	survival_streak = 0.0
	score_multiplier = 1
	Global.current_score = starting_score

	car_health -= 1
	print("Car hit! Health: %d/%d | Score reset to: %d" % [car_health, max_health, Global.current_score])

func reset_value() -> void:
	is_game_over = false
	run_score = 0.0
	survival_streak = 0.0
	score_multiplier = 1
	car_health = max_health
	progress_bar.visible = true

func _on_end_timer_timeout() -> void:
	end_level()

func end_level() -> void:
	if is_game_over:
		return
	is_game_over = true

	stop_level_entities()
	Global.current_score = starting_score + roundi(run_score)
	Global.skip_to_boss_chase = true
	print("Level cleared! Final Score: %d" % Global.current_score)

	Savedata.save_checkpoint(
		next_scene_path,
		1,
		Global.saved_player_health,
		Global.saved_player_damage_bonus,
		Global.current_score
	)

	get_tree().change_scene_to_file(next_scene_path)

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	Global.playerAlive = false
	Global.gameStarted = false

	stop_level_entities()
	progress_bar.visible = false

	update_score()
	get_tree().change_scene_to_file("res://Scenes/Menu/Retry.tscn")

func update_score() -> void:
	Global.previous_score = Global.current_score
	if Global.current_score > Global.high_score:
		Global.high_score = Global.current_score
	Global.current_score = 0

func stop_level_entities() -> void:
	spawner_timer.stop()
	end_timer.stop()
	$Parallax2D.autoscroll = Vector2.ZERO
	$Player.set_process(false)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func autosave_checkpoint() -> void:
	var current_path := scene_file_path if not scene_file_path.is_empty() else "res://Scenes/Level/level_2_ext.tscn"
	Savedata.save_checkpoint(
		current_path,
		1,
		Global.saved_player_health,
		Global.saved_player_damage_bonus,
		starting_score
	)
