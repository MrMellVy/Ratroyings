extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		close_screen()

func close_screen() -> void:
	queue_free()

	get_tree().change_scene_to_file("res://Scenes/Cutscene/cutscene_1.tscn")
