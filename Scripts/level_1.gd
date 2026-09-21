extends Node2D

@onready var SceneTransitionAnimation = $Fade_transition/Fade_transition/AnimationPlayer
@onready var world_camera: Camera2D = $WorldCamera

@export var starting_wave: int

var current_wave: int
@export var enemy_scene: PackedScene
@export var airenemy_scene: PackedScene

var last_spawn_position: Vector2 = Vector2(-9999, -9999)  
var min_spawn_distance: float = 100.0
var wave_spawn_ended: bool = false
var is_transitioning: bool = false

var current_wave_batches: Array = []
var current_batch_index: int = 0
var current_air_wave_batches: Array = []
var current_air_batch_index: int = 0

var is_spawning: bool = false
var total_enemies_alive: int = 0
var rand_x
var rand_y

func _ready() -> void:
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
	$Player.set_physics_process(false)
	$Player.set_process_unhandled_input(false)
	if Global.is_continuing:
		current_wave = Global.saved_wave
		Global.current_wave = current_wave
		$Player.health = Global.saved_player_health
		$Player.damage_bonus = Global.saved_player_damage_bonus
		$scoreLabels.layer = 1
		$scoreLabels.layer = 3
		
		$Player.set_physics_process(true)
		$Player.set_process_unhandled_input(true)
		$Player.movementInputMonitoring = Vector2(true,true)
		
		if current_wave == 2:
			world_camera.limit_left = -32
			world_camera.limit_right = 272
			
			$"Border Collision/BorderCollisionRight/CollisionShape2D".set_deferred("disabled", false)
			
			$Wave2ZoneTrigger.set_deferred("monitoring", false)
			$Wave2ZoneTrigger.hide()
			$Player.global_position = Vector2(50, 133)
			$scoreLabels.visible = true
			$scoreLabels/ScoreAnim.play("ScoreUp")
			$scoreLabels/WaveAnim.play("WaveUp")
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			
			await $scoreLabels/ScoreAnim.animation_finished
			await $scoreLabels/WaveAnim.animation_finished
			await $scoreLabels/MiddleWaveAnim.animation_finished
			await get_tree().create_timer(1.5).timeout
		position_to_next_wave()
		current_wave_batches = [1 + current_wave, 1 + current_wave]
		current_batch_index = 0
		current_air_batch_index = 0
		spawn_next_batch()
	else:
		current_wave = starting_wave
		Global.current_wave = current_wave
		$Player/PlayerHealthbar.visible = false
		await SceneTransitionAnimation.animation_finished
		$Player.set_physics_process(true)
		$Player.set_process_unhandled_input(true)
		$Player.movementInputMonitoring = Vector2(true,true)
		$Player/PlayerHealthbar.visible = true
		$scoreLabels.layer = 3
		if current_wave == 2:
			$Player/Label.visible = true
			open_path_to_zone_2()
		else:
			$Player/PlayerHealthbar.visible = true
			$Player/PlayerHealthbar.layer = 0
			await level_dialogue("CS_00_1")
			$Player/PlayerHealthbar.layer = 1
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			await $scoreLabels/MiddleWaveAnim.animation_finished
			position_to_next_wave()
		
func position_to_next_wave():
		if current_wave != 0:
			autosave_checkpoint()
			Global.moving_to_next_wave = true
			wave_spawn_ended = false
			is_spawning = true
		
		$Fade_transition.layer = 2
		$scoreLabels/ScoreAnim.play("ScoreDown")
		$scoreLabels/WaveAnim.play("WaveDown")
		$scoreLabels/MiddleWaveAnim.play("RightExit")
		await $scoreLabels/MiddleWaveAnim.animation_finished
		SceneTransitionAnimation.play("between_wave")
		$Player.apply_wave_stats(current_wave)

		
		if current_wave == 1:
			# Wave 1 will spawn 2 enemies, then 2, then 2
			current_wave_batches = [2, 2, 2]
			current_air_wave_batches = [0]
		elif current_wave == 3:
			Global.saved_wave = current_wave
			Global.is_continuing = true
			Global.saved_player_health = $Player.health
			Global.saved_player_damage_bonus = $Player.damage_bonus
			autosave_checkpoint()
			get_tree().change_scene_to_file("res://Scenes/Cutscene/cutscene_2.tscn")
		else:
			# Wave 2+ Wave3ZoneTriggerMORE! and this is where the airenemy spawn.
			current_wave_batches = [current_wave, current_wave]
			current_air_wave_batches = [current_wave, current_wave]
		current_batch_index = 0
		current_air_batch_index = 0
		#Fix for freeze bug happens when close the window.
		if is_inside_tree():
			await get_tree().create_timer(0.5).timeout
			if is_inside_tree():
				spawn_next_batch()

func spawn_next_batch():
	if not is_inside_tree():
		is_spawning = false
		return
	
	if current_batch_index > 0:
		if is_inside_tree():
			await  get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return

	if current_batch_index < current_wave_batches.size():
		var enemies_to_spawn = current_wave_batches[current_batch_index]
		for i in range(enemies_to_spawn):
			var enemy = enemy_scene.instantiate()
			enemy.z_index = 1

			# random spawn for SpawnPoint1 and SpawnPoint2
			if i % 2 == 0:
				enemy.global_position = $EnemySpawnPoint1.global_position
			else:
				enemy.global_position = $EnemySpawnPoint2.global_position
			if current_wave == 2: #<- remember this myslf, to move into other area but still in one scenes. GS mean Ground Spawn
				if i % 3 == 0:
					enemy.global_position = $EnemySpawnPoint2.global_position
				else:
					enemy.global_position = $EnemySpawnPoint3.global_position
			enemy.tree_exited.connect(check_enemy_count)

			
			total_enemies_alive += 1
			add_child(enemy)
			await get_tree().create_timer(0.4).timeout 
		current_batch_index += 1

	if current_air_batch_index < current_air_wave_batches.size():
		var air_enemies_to_spawn = current_air_wave_batches[current_air_batch_index]
		for i in range(air_enemies_to_spawn):
			var air_enemy = airenemy_scene.instantiate()
			air_enemy.z_index = 1

			var index_SPoint = i % 3
			if index_SPoint == 0:
				air_enemy.global_position = $AirEnemySpawnPoint2.global_position
			else:
				air_enemy.global_position = $AirEnemySpawnPoint3.global_position
			if current_wave == 2:
				if index_SPoint == 0:
					air_enemy.global_position = $AirEnemySpawnPoint2.global_position
				else:
					air_enemy.global_position = $AirEnemySpawnPoint3.global_position
			air_enemy.tree_exited.connect(check_enemy_count)
			total_enemies_alive += 1
			add_child(air_enemy)
			await get_tree().create_timer(0.4).timeout 
		current_air_batch_index += 1

	var ground_finish = current_batch_index >= current_wave_batches.size()
	var air_finish = current_air_batch_index >= current_air_wave_batches.size()
	
	if ground_finish and air_finish:
		wave_spawn_ended = true
	
	is_spawning = false
	
	if total_enemies_alive <= 0:
		trigger_next_phase()
		
func check_enemy_count():
	print("check_enemy_count: total =", total_enemies_alive, "is_spawning =", is_spawning)
	total_enemies_alive -= 1
	
	if total_enemies_alive <= 0 and not is_spawning:
		trigger_next_phase()

func trigger_next_phase():
	is_spawning = true
	if wave_spawn_ended:
		print("Wave Cleared! Starting Next Wave...")
		
		current_wave += 1
		Global.current_wave = current_wave
		
		if current_wave == 2 and not Global.is_continuing:
			$Player/Label.visible = true
			open_path_to_zone_2()
		elif current_wave == 3 and not Global.is_continuing:
			$scoreLabels.visible = false
			position_to_next_wave()
		else:
			$scoreLabels/ScoreAnim.play("ScoreUp")
			$scoreLabels/WaveAnim.play("WaveUp")
			$scoreLabels/MiddleWaveAnim.play("LeftStart")
			
			await $scoreLabels/ScoreAnim.animation_finished
			await $scoreLabels/WaveAnim.animation_finished
			await  $scoreLabels/MiddleWaveAnim.animation_finished
			await get_tree().create_timer(1.5).timeout
			
			position_to_next_wave()
	else:
		print("Batch Cleared! Spawning next batch...")
		spawn_next_batch()

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
	#put the sign point to the right here unc.
	$"Border Collision/BorderCollisionRight/CollisionShape2D".set_deferred("disabled", true)
	print("path to new zone open! waiting to move to the right.")
	
	var tween = create_tween()
	tween.tween_property(world_camera, "limit_right", 272, 2.0).set_trans(Tween.TRANS_SINE)

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
		rand_x = randi_range(-435, 298)
		if current_wave == 2:
			rand_x = randi_range(321, 799)
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
	if body.name == "Player" and current_wave == 2 and not is_spawning:
		print("Player reached Zone 2 Transition, Starting Wave")
		$Player/Label.visible = false
		#Disable the font sign here. with .hide()
		$Wave2ZoneTrigger.set_deferred("monitoring", false) #for failsafe
		$"Border Collision/BorderCollisionRight/CollisionShape2D".set_deferred("disabled", false)
		
		var tween = create_tween()
		tween.tween_property(world_camera, "limit_left", -32, 1.0).set_trans(Tween.TRANS_SINE)
		
		$scoreLabels.visible = false
		$Player/PlayerHealthbar.visible = false
		
		await level_dialogue("CS_00_2")
		
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

func autosave_checkpoint():
	Savedata.save_checkpoint(
		"res://Scenes/Level/level_1.tscn",
		current_wave,
		$Player.health,
		$Player.damage_bonus,
		Global.current_score
	)
