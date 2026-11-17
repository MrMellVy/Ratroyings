extends Node2D

@onready var SceneTransitionAnimation = $Fade_transition/Fade_transition/AnimationPlayer
@onready var boss_rat_1: CharacterBody2D = $BossRat1

@export var enemy_scene: PackedScene
@export var airenemy_scene: PackedScene

var last_spawn_position: Vector2 = Vector2(-9999, -9999)  
var min_spawn_distance: float = 100.0
var is_transitioning: bool = false
var minion_spawner_timer: Timer

func _ready() -> void:
	Global.enemies_passive = false

	$Fade_transition.show()
	$Fade_transition.layer = 2
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out_start")
	BgmManager.play_BGM("Battle Encounter")
	
	$player.set_physics_process(true)
	$player.set_process_unhandled_input(true)
	$player.movementInputMonitoring = Vector2(true, true)
	$player/PlayerHealthbar.visible = true
	
	if Global.is_continuing:
		$player.health = Global.saved_player_health
		$player.damage_bonus = Global.saved_player_damage_bonus
		Global.is_continuing = false
	else:
		$player.health = $player.health_max if "health_max" in $player else 100 
		$player.damage_bonus = 0
	if has_node("BorderCollision1"):
		$BorderCollision1/CollisionShape2D.set_deferred("disabled", false)
	if has_node("BorderCollision2"):
		$BorderCollision2/CollisionShape2D.set_deferred("disabled", false)

	boss_rat_1.show()
	boss_rat_1.get_node("UI").show()
	boss_rat_1.process_mode = Node.PROCESS_MODE_INHERIT
	start_boss_enemy_spawner()
	autosave_checkpoint()

func start_boss_enemy_spawner() -> void:
	if minion_spawner_timer == null:
		minion_spawner_timer = Timer.new()
		minion_spawner_timer.wait_time = 2.0
		minion_spawner_timer.timeout.connect(_manage_boss_minions)
		add_child(minion_spawner_timer)
	minion_spawner_timer.start()

func _manage_boss_minions() -> void:
	if boss_rat_1.defeat:
		if minion_spawner_timer:
			minion_spawner_timer.stop()
		return
		
	var active_ground := 0
	var active_air := 0
	
	for minion in get_tree().get_nodes_in_group("level_minions"):
		if is_instance_valid(minion) and not minion.defeat:
			if minion is Enemy: active_ground += 1
			elif minion is EnemyAir: active_air += 1
			
	if active_ground < 2:
		var ground_enemy = enemy_scene.instantiate()
		ground_enemy.z_index = 0
		ground_enemy.add_to_group("level_minions")
		ground_enemy.global_position = $EnemySpawnPoint1.global_position if randf() < 0.5 else $EnemySpawnPoint2.global_position
		add_child(ground_enemy)
		
	if active_air < 2:
		var air_enemy = airenemy_scene.instantiate() 
		air_enemy.z_index = 0
		air_enemy.add_to_group("level_minions")
		air_enemy.global_position = $AirEnemySpawnPoint1.global_position if randf() < 0.5 else $AirEnemySpawnPoint2.global_position
		add_child(air_enemy)
			
func _on_boss_fight_won() -> void:
	if minion_spawner_timer:
		minion_spawner_timer.stop()
	for minion in get_tree().get_nodes_in_group("level_minions"):
		if is_instance_valid(minion):
			minion.queue_free()

	print("Boss Defeated! Moving to Cutscene 5...")
	Global.saved_player_health = $player.health
	Global.saved_player_damage_bonus = $player.damage_bonus
	autosave_checkpoint()
	
	$player/PlayerHealthbar.visible = false
	get_tree().change_scene_to_file("res://Scenes/Cutscene/cutscene_5.tscn")

func _process(_delta):
	if !Global.playerAlive and !is_transitioning:
		is_transitioning = true
		Global.gameStarted = false
		$Fade_transition.show()
		$Fade_transition.layer = 2
		SceneTransitionAnimation.play("Fade_in")
		await SceneTransitionAnimation.animation_finished
		update_score()
		get_tree().change_scene_to_file("res://Scenes/Menu/Retry.tscn")
			
func update_score():
	Global.previous_score = Global.current_score
	if Global.current_score > Global.high_score:
		Global.high_score = Global.current_score
		Global.current_score = 0

func _on_timer_health_power_up_timeout() -> void:
	var active_powerups = get_tree().get_nodes_in_group("health_powerups")
	
	if active_powerups.size() > 2:
		return
		
	var obj = preload("res://Scenes/Other/SpawnHealth.tscn").instantiate()
	var _valid_position = false
	var new_position: Vector2
	
	for attempt in range(10):
		var rand_x = randi_range(-47, 1348) 
		var rand_y = -70
		new_position = Vector2(rand_x, rand_y)
	
		var too_close = false
		for powerup in active_powerups:
			if new_position.distance_to(powerup.global_position) < min_spawn_distance:
				too_close = true
				break
				
		if new_position.distance_to(last_spawn_position) >= min_spawn_distance and not too_close:
			_valid_position = true
			break
		
	obj.global_position = new_position
	last_spawn_position = new_position
	obj.add_to_group("health_powerups")
	
	if randf() < 0.5:
		obj.set_collision_mask_value(4, false)
	add_child(obj)

	$timer_health_power_up.wait_time = 7

#func _input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_K:
			#print("Cheat: Boss Defeated!")
			#boss_rat_1.take_damage(999999)
		#elif event.keycode == KEY_T:
			#Global.enemies_passive = !Global.enemies_passive

func autosave_checkpoint():
	Savedata.save_checkpoint(
		"res://Scenes/Level/level_3.tscn",
		1,
		$player.health,
		$player.damage_bonus,
		Global.current_score
	)
