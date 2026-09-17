extends Control

@onready var scroll_container = $VBoxContainer

var normal_speed: float = 60.0 
var is_scrolling: bool = false

func _ready() -> void:
	var screen_height = get_viewport_rect().size.y
	scroll_container.position.y = screen_height
	is_scrolling = true

func _process(delta: float) -> void:
	if not is_scrolling:
		return
		
	var current_speed = normal_speed

	if Input.is_action_pressed("attack"):
		current_speed = normal_speed * 4.0
	scroll_container.position.y -= current_speed * delta
	
	if scroll_container.position.y < -scroll_container.size.y:
		is_scrolling = false
		_on_credits_finished()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_scrolling:
		is_scrolling = false
		_on_credits_finished()

func _on_credits_finished() -> void:
	print("Credits finished! Returning to Main Menu...")
	
	Savedata.reset_save()
	Global.show_credits = true
	
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
