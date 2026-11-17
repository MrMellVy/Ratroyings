extends Node2D
@onready var selected_camera: Camera2D = $WorldCamera
@onready var transition_camera: Camera2D = $WorldCameraTransition
@onready var player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D

var TransitionTween: Tween
var TransitionZoomTween: Tween
var TransitionOffsetTween: Tween

var current_dialogue_index: int = 0
var advance_action: StringName = "attack"
var anim_is_moving: bool = false

var dialogue_is_active: bool = true
var max_lines: int = 5

func _ready() -> void:
	Savedata.save_cutscene_checkpoint("res://Scenes/Cutscene/cutscene_3.tscn")
	$Fade_transition.show()    
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out")
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

func _input(event: InputEvent) -> void:
	if not dialogue_is_active:
		return

	if event.is_action_pressed(advance_action):
		if Dialouge.get_node("NinePatchRect/AnimationPlayer").is_playing():
			return

func _on_dialogue_event(event_name: String) -> void:
	if event_name == "start_move":
		move_player_to_target($Target_Move5)
		await move_support_to_target($Support_Move1)
	elif event_name == "boss_camera_show":
		await  Dialouge.get_node("NinePatchRect/AnimationPlayer").animation_finished
		
		anim_is_moving = true
		await _change_camera($WorldCamera2, 1.0)
		Dialouge.get_node("NinePatchRect").visible = false

		await _change_camera($WorldCamera3, 1.5)
		$AudioStreamPlayer.play()
		$AnimationPlayer.play("Start_boss")
		$BOSSprite.play("skill")
		await _change_camera($WorldCamera4, 0.5)
		await _change_camera($WorldCamera2, 0.6)
		$Road_crack.play("roads_crack")
		$BOSSprite.play("idle")
		anim_is_moving = false
		
func start() -> void:
	$WorldCameraTransition.make_current()
	_change_camera($WorldCamera)
	Dialouge.start("CS_02")
	await  Dialouge.dialogue_finished
	
	dialogue_is_active = false
	
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")
	await  $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	
	Global.is_continuing = true
	get_tree().change_scene_to_file("res://Scenes/Level/level_2.tscn")

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
		"res://Scenes/Cutscene/cutscene_3.tscn",
		$Player.health,
		$Player.damage_bonus,
		Global.current_score
	)


func _change_camera(choose_camera: Camera2D, duration: float = 0.5):
	anim_is_moving = true
	Dialouge.set_process_input(false)
	
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	var target_transform: Transform2D = choose_camera.global_transform
	TransitionTween.tween_property(transition_camera, "global_transform", target_transform, duration).set_trans(Tween.TRANS_SINE)
	
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

	selected_camera = choose_camera
	
	await  TransitionTween.finished

	anim_is_moving = false
	Dialouge.set_process_input(true)
