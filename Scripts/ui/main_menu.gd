extends Control

var button_type = null
var fade_startup = false
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var settings_menu: Control = $Options
@onready var selected_camera: Camera2D = $Camera2D
@onready var transition_camera: Camera2D = $TransitionCamera
@onready var continue_button: TextureButton = $MainButtons/Button_Manager/Continue
@onready var reset_hold_bar: TextureProgressBar = $ResetHoldbar
@onready var reset_label: Label = $ResetLabel
@onready var start_button: TextureButton = $MainButtons/Button_Manager/Start

var TransitionTween: Tween
var TransitionZoomTween: Tween
var TransitionOffsetTween: Tween

var esc_hold_time: float = 0.0
var esc_reset_done: bool = false
const ESC_HOLD_TIME: float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_buttons.visible = true
	#settings_menu.visible = false

	$title.visible = true
	$Fade_transition.show()
	$Fade_transition/fade_timerstart.start()
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_out") 

	BgmManager.play_BGM("cyber_runner")
	fade_startup = true
	
	$TransitionCamera.make_current()
	if Global.show_credits == true:
		Global.show_credits = false
		_change_camera($Camera2D3)
	else:
		_change_camera($Camera2D)
	handle_connecting_signals()
	
	update_menu_buttons()
	
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	
	print("has save: ", Savedata.has_save(), ", scene path: ", Savedata.scene_path, ", valid save: ", Savedata.has_valid_save())

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		if not Global.is_demo_mode: 
			print("SECRET DEMO ACTIVATED!")
			Global.is_demo_mode = true
			
			if has_node("DemoLabel"):
				$DemoLabel.visible = true
			
			button_type = "demo"
			$Fade_transition.show()
			$Fade_transition/fade_timer.start()
			$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")
		return
	# ---------------------

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		if not esc_reset_done:
			esc_hold_time += delta
			reset_hold_bar.visible = true
			reset_hold_bar.value = esc_hold_time / ESC_HOLD_TIME * 100.0
			
			var remaining: float = max(0.0, ESC_HOLD_TIME - esc_hold_time)
			var seconds_left: int  = int(ceil(remaining))
			
			reset_label.text = tr("KEY_ResetHold") % seconds_left
	
		if esc_hold_time >= ESC_HOLD_TIME:
			Savedata.reset_save()
			esc_reset_done = true
			
			reset_label.text = "KEY_ResetAfter"
			reset_hold_bar.value = 100.0
			
			update_menu_buttons()
			
			print("ASave deleted")
	else:
		esc_hold_time = 0.0
		esc_reset_done = false
		reset_hold_bar.visible = false
		reset_hold_bar.value = 0.0
		reset_label.text = "KEY_ResetSave"

func update_menu_buttons() -> void:
	var has_save := Savedata.has_valid_save()
	
	$MainButtons/Button_Manager/Start.visible = not has_save
	continue_button.visible = has_save
	continue_button.disabled = not has_save

func _on_start_pressed() -> void:
	button_type = "start"
	await get_tree().process_frame
	if $AnimationBStart.current_animation == "ButtonPressed" and $AnimationBStart.is_playing():
		await $AnimationBStart.animation_finished
	$Fade_transition.show()
	$Fade_transition/fade_timer.start()
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")

func _on_continue_pressed() -> void:
	if not Savedata.has_valid_save():
		return
	
	continue_button.visible = true
	button_type = "continue"
	
	$Fade_transition.show()
	$Fade_transition/fade_timerstart.start()
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")

func _on_option_pressed() -> void:
	print("Settings Pressed")
	#main_buttons.visible = false
	#settings_menu.visible = true
	#settings_menu.set_process(true)
	#$title.visible = false
	#$RichTextLabel.visible = false
	if selected_camera == $Camera2D:
		_change_camera($Camera2D2)
	else:
		_change_camera($Camera2D)

func _on_exit_pressed() -> void:
	button_type = "exit"
	await get_tree().process_frame
	
	if $AnimationBExit.current_animation == "Buttonexitpressed" and $AnimationBExit.is_playing():
		await $AnimationBExit.animation_finished
	$Fade_transition.show()
	$Fade_transition/fade_timer.start()
	$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")

func _on_back_settings_menu() -> void:
	print("it work.")
	#main_buttons.visible = true
	#settings_menu.visible = false
	#$title.visible = true
	#$RichTextLabel.visible = true
	if $AnimationBSettings.current_animation == "ButtonSettingsPressed" and $AnimationBSettings.is_playing():
		await $AnimationBSettings.animation_finished
	if selected_camera == $Camera2D2:
		_change_camera($Camera2D)
	else:
		_change_camera($Camera2D2)
	

func _on_credits_button_pressed() -> void:
	if selected_camera == $Camera2D:
		_change_camera($Camera2D3)
	else:
		_change_camera($Camera2D)


func _on_back_creditsbutton_pressed() -> void:
	if selected_camera == $Camera2D3:
		_change_camera($Camera2D)
	else:
		_change_camera($Camera2D3)

func _on_fade_timer_timeout() -> void:
	if button_type == "start" :
		Global.gameStarted = true
		Savedata.save_checkpoint(
			"res://Scenes/Cutscene/cutscene_1.tscn",
			1,
			100,
			0
		)
		get_tree().change_scene_to_file("res://Scenes/Other/Keyboardshortcut.tscn")
	elif button_type == "continue":
		Global.gameStarted = true
		
		Savedata.load_checkpoint()
		
		Global.is_continuing = true
		Global.saved_wave = Savedata.wave
		Global.saved_player_health = Savedata.health
		Global.saved_player_damage_bonus = Savedata.damage_bonus
		
		get_tree().change_scene_to_file(Savedata.scene_path)
	elif button_type == "exit" :
		get_tree().quit()
	elif  button_type == "demo":
		Global.gameStarted = true
		Global.is_continuing = true
		Global.saved_wave = 4
		Global.saved_player_health = 150
		Global.saved_player_damage_bonus = 20
		get_tree().change_scene_to_file("res://Scenes/Other/Keyboardshortcut.tscn")
	elif fade_startup == true:
		$Fade_transition.hide()
		
func handle_connecting_signals() -> void:
	settings_menu.back_settings_menu.connect(_on_back_settings_menu)

func _change_camera(choose_camera: Camera2D) -> void:
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	var target_transform: Transform2D = choose_camera.global_transform
	TransitionTween.tween_property(transition_camera, "global_transform", target_transform, 1).set_trans(Tween.TRANS_SINE)
	
	if TransitionZoomTween:
		TransitionZoomTween.kill()
	TransitionZoomTween = create_tween()
	var target_zoom: Vector2 = choose_camera.zoom
	TransitionZoomTween.tween_property(transition_camera, "zoom", target_zoom, 1).set_trans(Tween.TRANS_SINE)
	
	if TransitionOffsetTween:
		TransitionOffsetTween.kill()
	TransitionOffsetTween = create_tween()
	var target_offset: Vector2 = choose_camera.offset
	TransitionOffsetTween.tween_property(transition_camera, "offset", target_offset, 1).set_trans(Tween.TRANS_SINE)

	selected_camera = choose_camera
