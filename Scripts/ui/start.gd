extends TextureButton

var original_pos: Vector2
var is_mouse_mode: bool = false
@onready var animation_player: AnimationPlayer = $"../../../AnimationBStart"


func _ready() -> void:
	grab_focus()
	original_pos = position

#To change mode, Mouse or Keyboard/Controller.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.relative.length() > 1.0 and not is_mouse_mode:
			is_mouse_mode = true
			release_focus() 
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if is_mouse_mode:
			is_mouse_mode = false
			grab_focus() 

func _on_mouse_entered() -> void:
	animation_player.play("buttonstart")

func _on_mouse_exited() -> void:
	animation_player.stop()

func _on_focus_entered() -> void:
	animation_player.play("buttonstart")

func _on_focus_exited() -> void:
	animation_player.stop()
	
func _on_button_down() -> void:
	animation_player.stop()
	if not is_mouse_mode:
		animation_player.play("ButtonPressed")
		await  animation_player.animation_finished
		
func _on_button_up() -> void:
	pass
