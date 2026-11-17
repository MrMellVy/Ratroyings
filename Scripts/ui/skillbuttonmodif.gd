extends TextureButton
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var time: Label = $Time
@onready var timer: Timer = $Timer
@onready var key: Label = $Key

signal cast(skill_name)

var change_key = "":
	set(value):
		change_key = value
		key.text = value

		shortcut = Shortcut.new()
		var input_key = InputEventKey.new()
		input_key.keycode = value.unicode_at(0)
		
		shortcut.events = [input_key]
		
func _ready() -> void:
	change_key = "1"
	texture_progress_bar.max_value = timer.wait_time
	
	self_modulate.a = 0.0
	time.visible = false
	#key.visible = false
	
	disabled = false #1
	set_process(false)

func _process(_delta: float) -> void:
	time.text = "%3.1f" % timer.time_left
	texture_progress_bar.value = timer.time_left


func _on_pressed() -> void:
	if disabled:
		return
	
	cast.emit(name)
	
func start_cooldown() -> void:
	timer.start()
	disabled = true
	set_process(true)
	cast.emit(name)
	self_modulate.a = 1.0
	time.visible = true
	#key.visible = true

func _on_timer_timeout() -> void:
	disabled = false
	time.text = ""
	set_process(false)
	self_modulate.a = 0.0
	#key.visible = false
