extends Area2D

@onready var mainScene = $".."
@onready var marker_2d: Marker2D = $Marker2D

var using_mouse: bool = true
var keyboard_speed: float = 250.0 

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		using_mouse = true
	elif event is InputEventKey and event.is_pressed():
		using_mouse = false

func _process(delta: float) -> void:
	if using_mouse:
		var mouse_pos = get_global_mouse_position()
		global_position.y = clamp(mouse_pos.y, 642, 690)
	else:

		var direction = Input.get_axis("jump", "down")
		global_position.y += direction * keyboard_speed * delta
		global_position.y = clamp(global_position.y, 642, 690)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and not area.get_meta("has_hit", false):
		area.set_meta("has_hit", true)
		area.queue_free()
		if is_instance_valid(mainScene) and mainScene.has_method("take_car_damage"):
			mainScene.take_car_damage()
