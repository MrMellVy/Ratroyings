extends Node2D
@onready var selected_camera: Camera2D = $Player/WorldCamera
@onready var transition_camera: Camera2D = $Player/WorldCameraTransition
@onready var player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D

var TransitionTween: Tween
var TransitionZoomTween: Tween
var TransitionOffsetTween: Tween

var current_dialogue_index: int = 0
var advance_action: StringName = "attack"
var anim_is_moving: bool = false

var dialogue_is_active: bool = true
var max_lines: int = 8

func _ready() -> void:
	Savedata.save_cutscene_checkpoint("res://Scenes/Cutscene/cutscene_2.tscn")

	$Fade_transition.show()    
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out")
	BgmManager.play_BGM("cyberpunk-street")

	var player = $Player
	player.can_use_skill = false
	player.set_process(false)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.set_collision_layer_value(1, false) 
	if has_node("Player/Actionbar"):
		$Player/Actionbar.process_mode = Node.PROCESS_MODE_DISABLED

	$Player/PlayerHealthbar/HealthBarContainer/PlayerHP.visible = false

	start()


func _input(event: InputEvent) -> void:
	if not dialogue_is_active:
		return

	if anim_is_moving:
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(advance_action):
		
		if Dialouge.get_node("NinePatchRect/AnimationPlayer").is_playing():
			return
		
		if current_dialogue_index >= max_lines:
			return
		
		current_dialogue_index += 1
		print("Dialogue Index: ", current_dialogue_index)
		#Index always start from zero yeah. 1,2,3,4 -> 0,1,2,3.
		if current_dialogue_index == 1:
			await move_player_to_target($Target_Move3)
		elif current_dialogue_index == 2:
			await move_player_to_target($Target_Move5)
		elif current_dialogue_index == 3:
			if selected_camera == $Player/WorldCamera:
				_change_camera($Player/WorldCamera2)
			else:
				_change_camera($Player/WorldCamera)
func start() -> void:
	$Player/WorldCameraTransition.make_current()
	_change_camera($Player/WorldCamera)
	Dialouge.start("CS_01")
	await  Dialouge.dialogue_finished
	
	dialogue_is_active = false
	
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")
	await  $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	
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
	tween.tween_property(player, "global_position", target_node.global_position, 1.5)
	await tween.finished
	player.PlayerSprite.play("idle")
	anim_is_moving = false

func _change_camera(choose_camera: Camera2D) -> void:
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	var target_transform: Transform2D = choose_camera.global_transform
	TransitionTween.tween_property(transition_camera, "global_transform", target_transform, 0.5).set_trans(Tween.TRANS_SINE)
	
	if TransitionZoomTween:
		TransitionZoomTween.kill()
	TransitionZoomTween = create_tween()
	var target_zoom: Vector2 = choose_camera.zoom
	TransitionZoomTween.tween_property(transition_camera, "zoom", target_zoom, 0.5).set_trans(Tween.TRANS_SINE)
	
	if TransitionOffsetTween:
		TransitionOffsetTween.kill()
	TransitionOffsetTween = create_tween()
	var target_offset: Vector2 = choose_camera.offset
	TransitionOffsetTween.tween_property(transition_camera, "offset", target_offset, 0.5).set_trans(Tween.TRANS_SINE)

	selected_camera = choose_camera
