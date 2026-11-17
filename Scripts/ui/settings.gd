class_name Settingsmenu
extends Control
@onready var back_button: Button = $Back

signal back_settings_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_button.button_down.connect(_on_back_pressed)
	set_process(false)
	
func _on_back_pressed() -> void:
	back_settings_menu.emit()
	set_process(false)
