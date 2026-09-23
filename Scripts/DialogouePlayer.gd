extends CanvasLayer

signal dialogue_finished
signal dialogue_event(event_name: String)
@export var test_dialogue: String = ""

var dialogue = []
var current_dialogue_id = 0
var d_active = false
var current_dialogue_name := ""

var bounce_tween: Tween
@onready var indicator = $NinePatchRect/Indicator
@onready var indicator_base_y = indicator.position.y

func _ready() -> void:
	$NinePatchRect.visible = false
	indicator.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("refresh_language")
	if get_tree().current_scene == self and test_dialogue != "":
		start(test_dialogue)

func start(dialogue_name: String):
	if d_active:
		return
	set_process_unhandled_input(true)
	current_dialogue_name = dialogue_name
	var target_file_path := get_localized_dialogue_path(dialogue_name)
	d_active = true
	$NinePatchRect.visible = true
	indicator.visible = false
	
	dialogue = load_dialogue(target_file_path)
	
	if dialogue == null or dialogue.is_empty():
		print("Dialogue array is empty or null. Check the errors above.")
		$NinePatchRect.visible = false
		d_active = false
		return
	current_dialogue_id = -1
	next_script()

func load_dialogue(file_path):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK:
			return json.data
		else:
			print("JSON ERROR in ", file_path)
			print("Line ", json.get_error_line(), ": ", json.get_error_message())
			return []
	else:
		print("error can't find any file at path: ", file_path)
		return []
	
func _unhandled_input(event):
	if not d_active:
		return
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		if $NinePatchRect/AnimationPlayer.is_playing():
			$NinePatchRect/AnimationPlayer.stop()
			$NinePatchRect/Dialogue.visible_ratio = 1.0
			$NinePatchRect/AnimationPlayer.animation_finished.emit("Dialogue")
		else:
			next_script()

func next_script():
	current_dialogue_id += 1
	if current_dialogue_id >= len(dialogue):
		stop()
		dialogue_finished.emit()
		return
	
	$NinePatchRect.visible = true
	
	indicator.visible = false 
	if bounce_tween:
		bounce_tween.kill()
	indicator.position.y = indicator_base_y 
	
	var current_line = dialogue[current_dialogue_id]
	$NinePatchRect/Name.text = current_line.get("name","Unw")
	$NinePatchRect/Dialogue.text = current_line.get('text',"...")

	var face_name = current_line.get("face","")
	if face_name != "":
		var path_1 = "res://Assets/Sprites/PlayerFace/" + face_name + ".png"
		var path_2 = "res://Assets/Sprites/SupportFace/" + face_name + ".png"
		if ResourceLoader.exists(path_1):
			$NinePatchRect/PictureProtait.texture = load(path_1)
		elif ResourceLoader.exists(path_2):
			$NinePatchRect/PictureProtait.texture = load(path_2)
		else:
			print("Face texture not found at", path_1)
			$NinePatchRect/PictureProtait.texture = null
	else:
		$NinePatchRect/PictureProtait.texture = null

	$NinePatchRect/AnimationPlayer.stop()
	$NinePatchRect/AnimationPlayer.play("Dialogue")
	
	if current_line.has("event"):
		dialogue_event.emit(current_line["event"])
	
	await $NinePatchRect/AnimationPlayer.animation_finished
	
	if not d_active or dialogue[current_dialogue_id] != current_line:
		return 
		
	if current_line.has("auto"):
		await get_tree().create_timer(current_line["auto"]).timeout
		if d_active and dialogue[current_dialogue_id] == current_line:
			next_script()
	else:
		_show_indicator()

func _show_indicator():
	indicator.visible = true
	if bounce_tween:
		bounce_tween.kill()
		
	bounce_tween = create_tween().set_loops()
	bounce_tween.tween_property(indicator, "position:y", indicator_base_y - 8, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bounce_tween.tween_property(indicator, "position:y", indicator_base_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func get_language_code() -> String:
	var locale := TranslationServer.get_locale()
	if locale == "":
		return "en"
	return locale.split("_")[0]

func get_localized_dialogue_path(dialogue_name: String) -> String:
	var base_path := "res://Scripts/Dialogue/"
	var language := get_language_code()
	var localized_path := base_path + dialogue_name + "_" + language + ".json"
	
	if FileAccess.file_exists(localized_path):
		return localized_path
	return base_path + dialogue_name + ".json"
	
func refresh_language() -> void:
	if not d_active:
		return
	if current_dialogue_name == "":
		return

	var old_id := int(current_dialogue_id)
	var target_file_path := get_localized_dialogue_path(current_dialogue_name)

	dialogue = load_dialogue(target_file_path)
	if dialogue == null or dialogue.is_empty():
		stop()
		return
	current_dialogue_id = int(clamp(old_id, 0, dialogue.size() - 1))
	refresh_current_line()
	
func refresh_current_line() -> void:
	if current_dialogue_id < 0  or current_dialogue_id >= dialogue.size():
		return
		
	var current_line = dialogue[current_dialogue_id]
	$NinePatchRect/Name.text = current_line.get("name", "Unw")
	$NinePatchRect/Dialogue.text = current_line.get("text", "...")
	
	var face_name = current_line.get("face", "")
	if face_name != "":
		var path_1 = "res://Assets/Sprites/PlayerFace/" + face_name + ".png"
		var path_2 = "res://Assets/Sprites/SupportFace/" + face_name + ".png"
		if ResourceLoader.exists(path_1):
			$NinePatchRect/PictureProtait.texture = load(path_1)
		elif ResourceLoader.exists(path_2):
			$NinePatchRect/PictureProtait.texture = load(path_2)
		else:
			print("Face Texture not found, ", face_name)
			$NinePatchRect/PictureProtait.texture = null
	else:
		$NinePatchRect/PictureProtait.texture = null

func stop() -> void:
	d_active = false
	$NinePatchRect.visible = false
	if bounce_tween:
		bounce_tween.kill()
	if indicator:
		indicator.visible = false
