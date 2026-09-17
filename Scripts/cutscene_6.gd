extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("car start")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("car move")
