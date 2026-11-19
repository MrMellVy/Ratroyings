extends Area2D

@export var speed: float = 150
@onready var mainScene = $'../..'

func _process(delta: float) -> void:
	position.x -= speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.get_parent().is_in_group("player"):
		if is_instance_valid(mainScene) and mainScene.has_method("take_car_damage"):
			mainScene.take_car_damage()
		queue_free()
