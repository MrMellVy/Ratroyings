extends CanvasLayer

@onready var fade_transition: CanvasLayer = $Fade_transition
@onready var settingmenu: Settingsmenu = $Options
@onready var pause_main_buttons: VBoxContainer = $PauseMainButtons

var is_menu_open: bool = false
var was_paused_before_menu: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false
	fade_transition.visible = false
	handle_connecting_signals()
	process_mode = Node.PROCESS_MODE_ALWAYS 

func _on_button_menu_pressed() -> void:
	fade_transition.visible = true
	#$Fade_transition/Fade_transition/AnimationPlayer.play("Fade_in")
	#await $Fade_transition/Fade_transition/AnimationPlayer.animation_finished
	var level = get_tree().current_scene
	
	if level and level.has_method("autosave_checkpoint"):
		level.autosave_checkpoint()
	Dialouge.stop()
	
	get_tree().paused = false
	BgmManager.set_pause_state(false)
	Savedata.save_current_scene_checkpoint()
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
	BgmManager.play_BGM("cyber_runner")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if is_menu_open:
			close_pause_menu()
		else:
			open_pause_menu()

func open_pause_menu() -> void:
	is_menu_open = true
	visible = true
	pause_main_buttons.visible = true
	settingmenu.visible = false
	
	was_paused_before_menu = get_tree().paused
	
	get_tree().paused = true
	BgmManager.set_pause_state(true)

func close_pause_menu() -> void:
	is_menu_open = false
	visible = false
	
	if settingmenu.visible:
		settingmenu.visible = true
		pause_main_buttons.visible = true
		
	get_tree().paused = was_paused_before_menu
	BgmManager.set_pause_state(was_paused_before_menu)

func _on_settings_pressed() -> void:
	print("it work.")
	pause_main_buttons.visible = false
	settingmenu.visible = true
	#$SettingsScreenAnim.play("OpenSettingsScreen")

func _on_back_settings_menu() -> void:
	print("Closing RN.")
	#$SettingsScreenAnim.play("CloseSettingsScreen")
	#
	#await $SettingsScreenAnim.animation_finished
	
	settingmenu.visible = false
	pause_main_buttons.visible = true

	#$ButtonAnim.play("ButtonIntro")
	#$BMenuAnim.play("IntroMenu")
	#$BSettingsAnim.play("IntroBSettings")
	
func handle_connecting_signals() -> void:
	settingmenu.back_settings_menu.connect(_on_back_settings_menu)

func _on_button_resume_pressed() -> void:
	if is_menu_open:
		close_pause_menu()
