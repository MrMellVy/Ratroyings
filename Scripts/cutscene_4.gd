extends Node2D
@onready var selected_camera: Camera2D = $WorldCamera
@onready var transition_camera: Camera2D = $WorldCameraTransition
@onready var player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D

var TransitionTween: Tween
var TransitionZoomTween: Tween
var TransitionOffsetTween: Tween
var TransitionRotationTween: Tween

var current_dialogue_index: int = 0
var advance_action: StringName = "attack"
var anim_is_moving: bool = false
var persistent_shake_power: float = 0.0
var impact_shake_power: float = 0.0

var dialogue_is_active: bool = true
var max_lines: int = 5

func _ready() -> void:
	Savedata.save_cutscene_checkpoint("res://Scenes/Cutscene/cutscene_4.tscn")

	BgmManager.play_BGM("cyberpunk-street")

	Dialouge.dialogue_event.connect(_on_dialogue_event)

	var player = $Player
	player.can_use_skill = false
	player.set_process(false)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.set_collision_layer_value(1, false) 
	
	if has_node("SupportCH"):
		var support = $SupportCH
		support.set_process(false)
		support.set_physics_process(false)
	
	if has_node("Player/Actionbar"):
		$Player/Actionbar.process_mode = Node.PROCESS_MODE_DISABLED

	$Player/PlayerHealthbar/HealthBarContainer/PlayerHP.visible = false
	start()

func _process(delta: float) -> void:
	if not TransitionTween or not TransitionTween.is_running():
		
		var total_shake = impact_shake_power + persistent_shake_power
		
		if total_shake > 0.0 and selected_camera:
			var random_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * total_shake
			transition_camera.global_transform.origin = selected_camera.global_transform.origin + random_offset
			
		elif total_shake == 0.0 and selected_camera:
			transition_camera.global_transform.origin = selected_camera.global_transform.origin

func _input(event: InputEvent) -> void:
	if not dialogue_is_active:
		return

	if not anim_is_moving:
		return
	
	if event.is_action_pressed(advance_action):
		if Dialouge.get_node("NinePatchRect/AnimationPlayer").is_playing():
			return

func _on_dialogue_event(event_name: String) -> void:
	if event_name == "attack_boss_move_back":
		anim_is_moving = true
		Dialouge.set_process_input(false)
		Dialouge.set_process_unhandled_input(false)
		Dialouge.get_node("NinePatchRect").visible = false
		
		_change_camera($WorldCamera2, 1.0)
		await move_player_to_target($Movetarget1)
		
		$Player/AnimatedSprite2D.play("single_attack_3")
		$BOSSprite.play("hurt")
		$AudioStreamPlayer.play()
		$AudioStreamPlayer2.play()
		$AnimationPlayer.play("Start_boss")
		
		await get_tree().create_timer(0.3).timeout
		_change_camera($WorldCamera3, 0.0, 3.0, 0.9)
		
		await get_tree().create_timer(2.0).timeout
		$AnimationPlayer.play("boss_run")
		$BOSSprite.flip_h = true
		$BOSSprite.play("walk")
		
		await $AnimationPlayer.animation_finished
		Dialouge.get_node("NinePatchRect").visible = true
		anim_is_moving = false
		Dialouge.set_process_input(true)
		Dialouge.set_process_shortcut_input(true)

	elif event_name == "showcar":
		anim_is_moving = true
		Dialouge.set_process_input(false)
		Dialouge.set_process_shortcut_input(false)
		
		$Player/AnimatedSprite2D.play("idle")
		_change_camera($WorldCamera4)
		$car.flip_h = true
		$Player.toggle_flip_sprite(-1)
		$AnimationPlayer.play("car_move")
		
		anim_is_moving = false
		Dialouge.set_process_input(true)
		Dialouge.set_process_shortcut_input(true)

	elif event_name == "boss_chase":
		anim_is_moving = true
		Dialouge.set_process_input(false)
		Dialouge.set_process_shortcut_input(false)
		Dialouge.get_node("NinePatchRect").visible = false

		_change_camera($WorldCamera5, 0.0)
		$AnimationPlayer.play("event_car_and_boss")
		await get_tree().create_timer(1.5).timeout
		_change_camera($WorldCamera7, 0.0)
		
		
func start() -> void:
	$WorldCameraTransition.make_current()
	_change_camera($WorldCamera)
	Dialouge.start("CS_03")
	await  Dialouge.dialogue_finished
	
	dialogue_is_active = false
	
	Global.is_continuing = true
	get_tree().change_scene_to_file("res://Scenes/Level/level_3.tscn")

func move_player_to_target(target_node: Node2D) -> void:
	anim_is_moving = true
	
	var player = $Player
	if target_node.global_position.x > player.global_position.x:
		player.toggle_flip_sprite(1)
	else:
		player.toggle_flip_sprite(-1)
	player.PlayerSprite.play("run")
	
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_node.global_position, 1.0)
	await tween.finished
	player.PlayerSprite.play("idle")
	anim_is_moving = false

func move_support_to_target(target_node: Node2D) -> void:
	anim_is_moving = true
	Dialouge.set_process_input(false)
	
	var support = $SupportCH
	if target_node.global_position.x > support.global_position.x:
		support.change_direction(1)
	else:
		support.change_direction(-1)
	support.Anim_sprite.play("run")
	
	var tween = create_tween()
	tween.tween_property(support, "global_position", target_node.global_position, 1.0)
	await tween.finished
	support.Anim_sprite.play("idle")
	anim_is_moving = false
	Dialouge.set_process_input(true)

func autosave_checkpoint():
	Savedata.save_checkpoint(
		"res://Scenes/Cutscene/cutscene_4.tscn",
		$Player.health,
		$Player.damage_bonus,
		Global.current_score
	)


func _change_camera(choose_camera: Camera2D, duration: float = 0.5, shake_power: float = 0.0, shake_duration: float = 0.5):
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	
	var start_transform: Transform2D = transition_camera.global_transform
	var target_transform: Transform2D = choose_camera.global_transform

	if shake_power > 0.0:
		impact_shake_power = shake_power
		var shake_tween = create_tween()
		shake_tween.tween_property(self, "impact_shake_power", 0.0, shake_duration)

	var move_step = func(weight: float):
		var current_trans = target_transform
		if duration > 0.0:
				current_trans = start_transform.interpolate_with(target_transform, weight)
		var total_shake = impact_shake_power + persistent_shake_power
		var random_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0,1.0)) * total_shake
		current_trans.origin += random_offset
		transition_camera.global_transform = current_trans
	var move_time = max(duration, 0.01)
	TransitionTween.tween_method(move_step, 0.0, 1.0, move_time).set_trans(Tween.TRANS_SINE)

	if TransitionZoomTween:
		TransitionZoomTween.kill()
	TransitionZoomTween = create_tween()
	var target_zoom: Vector2 = choose_camera.zoom
	TransitionZoomTween.tween_property(transition_camera, "zoom", target_zoom, duration).set_trans(Tween.TRANS_SINE)
	
	if TransitionOffsetTween:
		TransitionOffsetTween.kill()
	TransitionOffsetTween = create_tween()
	var target_offset: Vector2 = choose_camera.offset
	TransitionOffsetTween.tween_property(transition_camera, "offset", target_offset, duration).set_trans(Tween.TRANS_SINE)

	if TransitionRotationTween:
		TransitionRotationTween.kill()
	TransitionRotationTween = create_tween()
	var target_rotation: float = choose_camera.global_rotation
	TransitionRotationTween.tween_property(transition_camera, "rotation", target_rotation, duration).set_trans(Tween.TRANS_SINE)


	selected_camera = choose_camera
	
	await  TransitionTween.finished
