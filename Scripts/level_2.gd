extends Node2D

@onready var SceneTransitionAnimation = $Fade_transition/Fade_transition/AnimationPlayer
@onready var world_camera: Camera2D = $WorldCamera
@onready var boss_rat_1: CharacterBody2D = $BossRat1

@export var starting_wave: int = 3

var current_wave: int
@export var enemy_scene: PackedScene
@export var airenemy_scene: PackedScene

var last_spawn_position: Vector2 = Vector2(-9999, -9999)  
var min_spawn_distance: float = 100.0
var wave_spawn_ended: bool = false
var is_transitioning: bool = false

var minion_spawner_timer: Timer
var current_wave_batches: Array = []
var current_batch_index: int = 0
var current_air_wave_batches: Array = []
var current_air_batch_index: int = 0

var all_batches_spawned: bool = false
var active_batch_index: int = -1
var batch_emy_defeated_count: int = 0
var batch_emy_defeated_threshold: int = 0
var is_changing_phase: bool = false

var is_spawning: bool = false
var total_enemies_alive: int = 0
var rand_x
var rand_y

func _ready() -> void:
	boss_rat_1.hide()
	boss_rat_1.get_node("UI").hide()
	boss_rat_1.process_mode = Node.PROCESS_MODE_DISABLED
	
	Global.enemies_passive = false
	#region for camera movement.
	world_camera.make_current()
	$Player.world_camera = world_camera
	
	var remote = RemoteTransform2D.new()
	$Player.add_child(remote)
	remote.remote_path = remote.get_path_to(world_camera)
	#endregion
	
	$Fade_transition.show()
	$Fade_transition.layer = 2
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out_start")
	
	BgmManager.play_BGM("Battle Encounter")
	show_skill_label()
	$Player.set_physics_process(false)
	$Player.set_process_unhandled_input(false)
	
	if Global.is_continuing:
		current_wave = Global.saved_wave
		Global.current_wave = current_wave
		$Player.health = Global.saved_player_health
		$Player.damage_bonus = Global.saved_player_damage_bonus
		
		$scoreLabels.layer = 1
		SceneTransitionAnimation.animation_finished
		$scoreLabels.layer = 3
		
		#await level_dialogue("CS_01_1")
		
		$Player.set_physics_process(true)
		$Player.set_process_unhandled_input(true)
		$Player.movementInputMonitoring = Vector2(true, true)
		$Player/PlayerHealthbar.visible = true
		
		if current_wave == 4:
			open_path_to_zone_2()
		elif current_wave == 5:
			world_camera.limit_left = 711
			world_camera.limit_right = 1388
			world_camera.zoom = Vector2(4.0, 4.0)

			$Fade_transition.show()
			$Fade_transition.layer = 2
			$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out_start")
			await $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	
			$"Border Collision/BorderCollisionRight2/CollisionShape2D".set_deferred("disabled", false)
			if has_node("Wave3ZoneTrigger"):
				$Wave3ZoneTrigger/CollisionShape2D.set_deferred("disabled", true)
			
			$Player.global_position = Vector2(745, 165)
			$SupportCH.global_position = Vector2(760, 165)
			boss_rat_1.show()
			boss_rat_1.get_node("UI").show()
			boss_rat_1.process_mode = Node.PROCESS_MODE_INHERIT
			
			start_boss_enemy_spawner()
			
			$scoreLabels.visible = true
			$Player/PlayerHealthbar.visible = true
			
			Global.current_wave = current_wave
			
			$scoreLabels/ScoreAnim.play("ScoreUp")
			$scoreLabels/WaveAnim.play("WaveUp")
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			
			await $scoreLabels/ScoreAnim.animation_finished
			await $scoreLabels/WaveAnim.animation_finished
			await $scoreLabels/MiddleWaveAnim.animation_finished
			
			await get_tree().create_timer(1.5).timeout
			position_to_next_wave()
		else:
			await start_wave_intro()
		Global.is_continuing = false
	else:
		current_wave = starting_wave
		Global.current_wave = current_wave
		
		$Player.set_physics_process(true)
		$Player.set_process_unhandled_input(true)
		$Player.movementInputMonitoring = Vector2(true, true)
		$Player/PlayerHealthbar.visible = true
		
		if current_wave == 4:
			world_camera.limit_right = 687
			world_camera.limit_left = 164

			$Fade_transition.show()
			$Fade_transition.layer = 2
			$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out_start")
			await $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	
			$"Border Collision/BorderCollisionRight2/CollisionShape2D".set_deferred("disabled", false)
			if has_node("Wave2ZoneTrigger"):
				$Wave2ZoneTrigger/CollisionShape2D.set_deferred("disabled", true)
			
			$Player.global_position = Vector2(180, 165)
			$SupportCH.global_position = Vector2(170, 165)
			$SupportCH.set_collision_mask_value(6, true)
			
			$scoreLabels.visible = true
			$Player/PlayerHealthbar.visible = true
			
			Global.current_wave = current_wave
			
			$scoreLabels/ScoreAnim.play("ScoreUp")
			$scoreLabels/WaveAnim.play("WaveUp")
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			
			await $scoreLabels/ScoreAnim.animation_finished
			await $scoreLabels/WaveAnim.animation_finished
			await $scoreLabels/MiddleWaveAnim.animation_finished
			
			await get_tree().create_timer(1.5).timeout
			position_to_next_wave()
		elif current_wave == 5:
			world_camera.limit_left = 711
			world_camera.limit_right = 1388
			world_camera.zoom = Vector2(4.0, 4.0)
	
			$Fade_transition.show()
			$Fade_transition.layer = 2
			$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out_start")
			await $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	
			$"Border Collision/BorderCollisionRight2/CollisionShape2D".set_deferred("disabled", false)
			if has_node("Wave3ZoneTrigger"):
				$Wave3ZoneTrigger/CollisionShape2D.set_deferred("disabled", true)
			
			$Player.global_position = Vector2(745, 165)
			$SupportCH.global_position = Vector2(760, 165)
			$SupportCH.set_collision_mask_value(6, true)

			boss_rat_1.show()
			boss_rat_1.get_node("UI").show()
			boss_rat_1.process_mode = Node.PROCESS_MODE_INHERIT
			
			start_boss_enemy_spawner()
			
			$scoreLabels.visible = true
			$Player/PlayerHealthbar.visible = true
			
			Global.current_wave = current_wave
			
			$scoreLabels/ScoreAnim.play("ScoreUp")
			$scoreLabels/WaveAnim.play("WaveUp")
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			
			await $scoreLabels/ScoreAnim.animation_finished
			await $scoreLabels/WaveAnim.animation_finished
			await $scoreLabels/MiddleWaveAnim.animation_finished
			
			await get_tree().create_timer(1.5).timeout
			position_to_next_wave()
		else:
			await start_wave_intro()
			
func position_to_next_wave():
		autosave_checkpoint()
		wave_spawn_ended = false
		is_changing_phase = false
		all_batches_spawned = false
		active_batch_index = -1
		batch_emy_defeated_count = 0
		batch_emy_defeated_threshold = 0
		total_enemies_alive = 0
		is_spawning = false
		
		$Fade_transition.layer = 2
		$scoreLabels/ScoreAnim.play("ScoreDown")
		$scoreLabels/WaveAnim.play("WaveDown")
		$scoreLabels/MiddleWaveAnim.play("RightExit")
		await $scoreLabels/MiddleWaveAnim.animation_finished
		SceneTransitionAnimation.play("between_wave")
		$Player.apply_wave_stats(current_wave)
		
		match current_wave:
			3:
				current_wave_batches = [2,2,1]
				current_air_wave_batches = [1,1,1]
			4:
				if Global.is_demo_mode:
					current_wave_batches = [2,2]
					current_air_wave_batches =[2,2]
				else:
					current_wave_batches = [1,2,1]
					current_air_wave_batches = [1,2,1]
			_:
				current_wave_batches = [1,1]
				current_air_wave_batches = [1,1]
		current_batch_index = 0
		#Fix for freeze bug happens when close the window.
		if is_inside_tree():
			await get_tree().create_timer(0.5).timeout
			if is_inside_tree():
				spawn_next_batch()

func start_wave_intro():
	$scoreLabels.visible = true
	$scoreLabels.layer = 3
	
	$scoreLabels/MiddleWaveAnim.stop()
	$scoreLabels/MiddleWaveAnim.play("LeftStart", -1.0, 1.0, false)
	await $scoreLabels/MiddleWaveAnim.animation_finished
	
	position_to_next_wave()
	
func spawn_next_batch():
	if not is_inside_tree():
		return

	if is_spawning:
		return

	if current_batch_index >= current_wave_batches.size():
		all_batches_spawned = true
		wave_spawn_ended = true
		
		if total_enemies_alive <= 0:
			trigger_next_phase()
		return

	is_spawning = true

	if current_batch_index > 0:
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			is_spawning = false
			return

	var batch_index := current_batch_index
	active_batch_index = batch_index
	batch_emy_defeated_count = 0
	
	var ground_count: int = current_wave_batches[batch_index]
	
	var air_count: int = 0
	if batch_index < current_wave_batches.size():
		air_count = current_air_wave_batches[batch_index]
		
	var total_in_batch: int = ground_count + air_count
	
	if total_in_batch <= 0:
		current_batch_index += 1
		is_spawning = false
		spawn_next_batch()
		return
		#if 50% enemies batch defeated, spawn next batch. I think.
	batch_emy_defeated_threshold = int(ceil(total_in_batch / 2.0))
		
	for i in range(ground_count):
		var enemy = enemy_scene.instantiate()
		enemy.z_index = 1
		enemy.set_meta("batch_index", batch_index)
	
		# random spawn for SpawnPoint1 and SpawnPoint2
		if i % 2 == 0:
			enemy.global_position = $EnemySpawnPoint1.global_position
		else:
			enemy.global_position = $EnemySpawnPoint2.global_position
		if current_wave == 4: #<- remember this myslf, to move into other area but still in one scenes.
			if i % 3 == 0:
				enemy.global_position = $EnemySpawnPoint3.global_position
			else:
				enemy.global_position = $EnemySpawnPoint4.global_position
		enemy.tree_exited.connect(_on_enemy_defeated.bind(enemy))
		total_enemies_alive += 1
		add_child(enemy)
		await get_tree().create_timer(0.4).timeout 


	for i in range(air_count):
		var air_enemy = airenemy_scene.instantiate()
		air_enemy.z_index = 1

		var index_SPoint = i % 3
		if index_SPoint == 0:
			air_enemy.global_position = $AirEnemySpawnPoint1.global_position
		elif index_SPoint == 1:
			air_enemy.global_position = $AirEnemySpawnPoint2.global_position
		else:
			air_enemy.global_position = $AirEnemySpawnPoint3.global_position
		if current_wave == 4:
			if index_SPoint == 0:
				air_enemy.global_position = $AirEnemySpawnPoint4.global_position
			elif index_SPoint == 1:
				air_enemy.global_position = $AirEnemySpawnPoint5.global_position
			else:
				air_enemy.global_position = $AirEnemySpawnPoint6.global_position
		air_enemy.tree_exited.connect(_on_enemy_defeated.bind(air_enemy))
		total_enemies_alive += 1
		add_child(air_enemy)
		await get_tree().create_timer(0.4).timeout 
	
	current_batch_index += 1
	is_spawning = false
	
	if current_batch_index >= current_wave_batches.size():
		all_batches_spawned = true
		wave_spawn_ended = true
	
	_check_dynamic_spawn()
	
	if all_batches_spawned and total_enemies_alive <= 0:
		trigger_next_phase()
	
func _on_enemy_defeated(enemy: Node):
	print("check_enemy_count: total =", total_enemies_alive, "is_spawning =", is_spawning)
	total_enemies_alive -= 1
	
	if enemy.has_meta("batch_index"):
		if enemy.get_meta("batch_index") == active_batch_index:
			batch_emy_defeated_count += 1
			
	if total_enemies_alive <= 0 and all_batches_spawned:
		trigger_next_phase()
		return
	
	_check_dynamic_spawn()
	
func trigger_next_phase():
	if is_changing_phase:
		return
	
	if not all_batches_spawned:
		_check_dynamic_spawn()
		return
		
	is_changing_phase = true
	
	print("wave clear, next.")
	current_wave += 1
	Global.current_wave = current_wave
	
	if current_wave == 4:
		$Player/Label.visible = true
		open_path_to_zone_2()
	elif current_wave == 5:
		$Player/Label.visible = true
		open_path_to_zone_3()
	else:
		is_spawning = true
		
		$scoreLabels/MiddlecurrentwaveLabel.visible = true
		
		$scoreLabels/ScoreAnim.play("ScoreUp")
		$scoreLabels/WaveAnim.play("WaveUp")
		$scoreLabels/MiddleWaveAnim.play("LeftStart")

		await $scoreLabels/ScoreAnim.animation_finished
		await $scoreLabels/WaveAnim.animation_finished
		await $scoreLabels/MiddleWaveAnim.animation_finished
		await get_tree().create_timer(1.5).timeout

		is_changing_phase = false
		position_to_next_wave()
		
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

func open_path_to_zone_2():
	is_spawning = false
	
	$scoreLabels/MiddlecurrentwaveLabel.visible = false
	
	#put the sign point to the right here unc.
	$"Border Collision/BorderCollisionRight/CollisionShape2D".set_deferred("disabled", true)
	print("path to new zone open! waiting to move to the right.")
	
	var tween = create_tween()
	tween.tween_property(world_camera, "limit_right", 687, 2.0).set_trans(Tween.TRANS_SINE)

func open_path_to_zone_3():
	is_spawning = false
	$scoreLabels.visible = false
	$"Border Collision/BorderCollisionRight2/CollisionShape2D".set_deferred("disabled", true)
	print("Path to zone 3 open, waiting to move to the right.")
	
	var tween = create_tween()
	tween.tween_property(world_camera, "limit_right", 1463, 2.0).set_trans(Tween.TRANS_SINE)

func show_skill_label() -> void:
	$Player/Label3.modulate.a = 1.0
	$Player/Label3.show()

	await get_tree().create_timer(5.0).timeout
	
	var tween = create_tween()
	tween.tween_property($Player/Label3, "modulate:a", 0.0, 1.0)
	
	await  tween.finished
	$Player/Label3.hide()
	await get_tree().create_timer(1.0).timeout
	$Player/Label2.modulate.a = 1.0
	$Player/Label2.show()

	await get_tree().create_timer(5.0).timeout
	var tween2 = create_tween()
	tween2.tween_property($Player/Label2, "modulate:a", 0.0, 1.0)
	
	await  tween.finished
	$Player/Label2.hide()

func _on_timer_health_power_up_timeout() -> void:
	var active_powerups = get_tree().get_nodes_in_group("health_powerups")
	var current_count = active_powerups.size()
	
	# If there are 3 or more on screen, skip spawning.
	if current_count > 2:
		print("Waiting... Powerups on screen: ", current_count)
		return
	var obj = preload("res://Scenes/Other/SpawnHealth.tscn").instantiate()
	
	var _valid_position = false
	var new_position: Vector2
	var max_attempts = 10
	
	for attempt in range(max_attempts):
		rand_x = randi_range(-435, 140)
		if current_wave == 4:
			rand_x = randi_range(164, 687)
		if current_wave == 5:
			rand_x = randi_range(711, 1463)
		rand_y = -70
		new_position = Vector2(rand_x, rand_y)
	
		var distance_from_last = new_position.distance_to(last_spawn_position)
		
		var too_close_to_any = false
		for powerup in active_powerups:
			var distance_to_powerup = new_position.distance_to(powerup.global_position)
			if distance_to_powerup < min_spawn_distance:
				too_close_to_any = true
				break
				
		if distance_from_last >= min_spawn_distance and not too_close_to_any:
			_valid_position = true
			break
		
	obj.global_position = new_position
	last_spawn_position = new_position
	
	obj.add_to_group("health_powerups")
	
	#powerup fall from the sky can bypass the platfrom and fall to the ground. By 50%
	if randf() < 0.5:
		obj.set_collision_mask_value(4, false)
	add_child(obj)

	var cooldown = 20
	if current_wave > 1:
		cooldown = 17.0 - ((current_wave - 2) * 2.0)
		cooldown = max(cooldown, 10.0)
	cooldown = max(cooldown, 10.0)
	$TimerHealthPowerUp.wait_time = cooldown
	print("Health Cooldown set to: ", cooldown, " seconds for Wave ", current_wave)


func _on_wave_2_zone_trigger_body_entered(body: Node2D) -> void:
	if body.name == "Player" and current_wave == 4 and not is_spawning:
		print("Player reached Zone 2 Transition, Starting Wave")

		#Disable the font sign here. with .hide()
		$Player/Label.visible = false
		$Wave2ZoneTrigger.set_deferred("monitoring", false) #for failsafe
		$"Border Collision/BorderCollisionRight/CollisionShape2D".set_deferred("disabled", false)
		
		var tween = create_tween()
		tween.tween_property(world_camera, "limit_left", 164, 1.0).set_trans(Tween.TRANS_SINE)

		position_to_next_wave()

#func _input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_K:
			#print("SKIP. Next Batch.")
			#for child in get_children():
				#if child is Enemy or child is EnemyAir:
					#if not child.defeat:
						#child.take_damage(999999)
		#elif event.keycode == KEY_T:
			#Global.enemies_passive = !Global.enemies_passive
			#
			#if Global.enemies_passive:
				#print("Enemies stop target player.")
			#else:
				#print("Enemies target player again.")


func level_dialogue(json_filename: String) -> void:
	get_tree().paused = true
	Dialouge.start(json_filename)
	await Dialouge.dialogue_finished
	get_tree().paused = false

func _check_dynamic_spawn():
	if all_batches_spawned:
		return
	if is_spawning:
		return
	if batch_emy_defeated_count >= batch_emy_defeated_threshold:
		spawn_next_batch()



func autosave_checkpoint():
	Savedata.save_checkpoint(
		"res://Scenes/Level/level_2.tscn",
		current_wave,
		$Player.health,
		$Player.damage_bonus,
		Global.current_score
	)

func start_boss_enemy_spawner() -> void:
	print("Starting boss minion spawner")
	if minion_spawner_timer == null:
		minion_spawner_timer = Timer.new()
		minion_spawner_timer.wait_time = 2.0
		minion_spawner_timer.timeout.connect(_manage_boss_minions)
		add_child(minion_spawner_timer)
		
	minion_spawner_timer.start()

func _manage_boss_minions() -> void:
	if current_wave != 5 or boss_rat_1.defeat:
		if minion_spawner_timer:
			if minion_spawner_timer:
				minion_spawner_timer.stop()
			return
	var active_ground := 0
	var active_air := 0
	
	for minion in get_tree().get_nodes_in_group("level_minions"):
		if is_instance_valid(minion) and not minion.defeat:
			if minion is Enemy:
				active_ground += 1
			elif minion is EnemyAir:
				active_air += 1
		if active_ground < 2:
			var ground_enemy = enemy_scene.instantiate()
			ground_enemy.z_index = 1
			ground_enemy.add_to_group("level_minions")
			
			ground_enemy.global_position = $EnemySpawnPoint1.global_position if  randf() < 0.5 else $EnemySpawnPoint4.global_position
			add_child(ground_enemy)
		if active_air < 2:
			var air_enemy = enemy_scene.instantiate()
			air_enemy.z_index = 1
			air_enemy.add_to_group("level_minions")
			
			air_enemy.global_position = $AirEnemySpawnPoint5.global_position if  randf() < 0.5 else $AirEnemySpawnPoint6.global_position
			add_child(air_enemy)
			
func _on_boss_fight_won() -> void:
	if minion_spawner_timer:
		minion_spawner_timer.stop()
	for minion in get_tree().get_nodes_in_group("level_minions"):
		if is_instance_valid(minion):
			minion.queue_free()
	
	print("Clear move to cutscene 4!")
	Global.saved_wave = 6
	Global.saved_player_health = $Player.health
	Global.saved_player_damage_bonus = $Player.damage_bonus
	autosave_checkpoint()
	get_tree().change_scene_to_file("res://Scenes/Cutscene/cutscene_4.tscn")

func _on_wave_3_zone_trigger_body_entered(body: Node2D) -> void:
	if body.name == "Player" and current_wave == 5 and not is_spawning:
		$Player/Label.visible = false
		print("Player reached Zone 3 Transition to cutscene ")
		$Wave3ZoneTrigger.set_deferred("monitoring", false)

		Global.saved_wave = 5
		Global.saved_player_health = $Player.health
		Global.saved_player_damage_bonus = $Player.damage_bonus
		autosave_checkpoint()
		
		get_tree().change_scene_to_file("res://Scenes/Cutscene/cutscene_3.tscn")
