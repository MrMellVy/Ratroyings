extends HBoxContainer

var skills: Array
@onready var debug: Label = $"../Debug"

func _ready() -> void:
	skills = get_children()
	
	for i in get_child_count():
		var button = skills[i]
		
		button.cast.connect(_on_skill_cast.bind(button))

		if i == 0:
			skills[i].change_key = "C"
		else:
			skills[i].change_key = str(i+1)

func _on_skill_cast(skill_name: String, button: TextureButton) -> void:
	debug.text = skill_name
	
	var player = Global.playerBody
	if player == null:
		return
	
	if "can_use_skill" in player and not player.can_use_skill:
		return
	
	var success := false
	
	match  skill_name:
		"SkillA":
			if player.has_method("try_perform_skill_a"):
				success = player.try_perform_skill_a()
			elif player.is_on_floor():
				player.perform_skill_a()
				success = true
		_:
			print("No skill assigned for: ", skill_name)

	if success and button.has_method("start_cooldown"):
		button.start_cooldown()
