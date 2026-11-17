extends Node

const SAVE_PATH := "user://autosave.fish"

var scene_path := "res://Scenes/Cutscene/cutscene_1.tscn"
var wave := 1
var health := 100
var damage_bonus := 0
var score := 0

func _ready() -> void:
	load_checkpoint()
	
func save_checkpoint(
	p_scene_path: String,
	p_wave: int,
	p_health: int,
	p_damage_bonus: int,
	p_score: int = 0
) -> void:
	scene_path = p_scene_path
	wave = p_wave
	health = p_health
	damage_bonus = p_damage_bonus
	score = p_score
	
	var config := ConfigFile.new()
	
	config.set_value("autosave", "scene_path", scene_path)
	config.set_value("autosave", "wave", wave)
	config.set_value("autosave", "health", health)
	config.set_value("autosave", "damage_bonus", damage_bonus)
	config.set_value("autosave", "score", score)

	config.save(SAVE_PATH)
	
	print("Autosave: ", scene_path, " | Wave: ", wave, " | Score: ", score)

func save_cutscene_checkpoint(p_scene_path: String) -> void:
	scene_path = p_scene_path
	var config := ConfigFile.new()

	config.set_value("autosave", "scene_path", scene_path)
	config.set_value("autosave", "wave", wave)
	config.set_value("autosave", "health", health)
	config.set_value("autosave", "damage_bonus", damage_bonus)
	config.set_value("autosave", "score", score)
	
	config.save(SAVE_PATH)
	print("Autosave: ", scene_path)

func load_checkpoint() -> void:
	var config := ConfigFile.new()
	
	if config.load(SAVE_PATH) != OK:
		print("No autosave found.")
		return
	
	scene_path = config.get_value("autosave", "scene_path", "res://Scenes/Level/level_1.tscn")
	wave = config.get_value("autosave", "wave", 1)
	health = config.get_value("autosave", "health", 100)
	damage_bonus = config.get_value("autosave", "damage_bonus", 0)
	score = config.get_value("autosave", "score", 0)

	print("Autosave loaded: ", scene_path, " | Wave: ", wave, " | Score: ", score)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
	
func has_valid_save() -> bool:
	if not has_save():
		return false
	
	if scene_path == "":
		return false
		
	return ResourceLoader.exists(scene_path)

func save_current_scene_checkpoint() -> void:
	if not Global.gameStarted:
		return
	
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
		
	var path: String = current_scene.scene_file_path
	if path.is_empty():
		return
	
	var lower_path := path.to_lower()
	
	# Stopping checkpoints to save main menu or retry.
	if lower_path.contains("main_menu") or lower_path.contains("retry"):
		return

	var player = Global.playerBody
	var hp := 100
	var dmg := 0
	
	if is_instance_valid(player):
		hp = player.health
		dmg = player.damage_bonus
		
	var wave_to_save: int = max(1, Global.current_wave)
	
	save_checkpoint(path, wave_to_save, hp, dmg, Global.current_score)

func _notification(what: int) -> void:
	if what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		save_current_scene_checkpoint()
		get_tree().quit()

func reset_save() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.remove(SAVE_PATH.get_file())
		
	scene_path = "res://Scenes/Cutscene/cutscene_1.tscn"
	wave = 1
	health = 100
	damage_bonus = 0
	
	print("ASave reset.")
