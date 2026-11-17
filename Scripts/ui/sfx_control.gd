extends HSlider

@export var audio_bus_name : String
@onready var SFX_label: Label = $SFXLabel
@onready var SFX_icon_btn: TextureButton = $SFXIcon

var audio_bus_id
var previous_volume: float = 1.0

var icon_normal = preload("res://Assets/Other/Tweak/Volume Ori/Volume.png")
var icon_mid = preload("res://Assets/Other/Tweak/Volume Ori/Volume_mid.png")
var icon_muted = preload("res://Assets/Other/Tweak/Volume Ori/Volume_muted.png")

func _ready() -> void:
	SFX_Control()

func SFX_Control() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	var current_db = AudioServer.get_bus_volume_db(audio_bus_id)
	value = db_to_linear(current_db)

	_update_ui(value)
	if SFX_icon_btn:
		SFX_icon_btn.pressed.connect(_on_SFX_icon_pressed)
		
func _on_SFX_icon_pressed() -> void:
	if value > 0.0:
		previous_volume = value
		value = 0.0
	else:
		value = previous_volume if previous_volume > 0.0 else 1.0

func _update_ui(value: float) -> void:
	var percentage = int(value * 100)
	if SFX_label:
		if percentage == 0:
			SFX_label.text = "Muted"
		else:
			SFX_label.text = str(percentage) + "%"

	if SFX_icon_btn:
		if value <= 0.0:
			SFX_icon_btn.texture_normal = icon_muted
		elif value < 0.5:
			SFX_icon_btn.texture_normal = icon_mid
		else:
			SFX_icon_btn.texture_normal = icon_normal
func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	_update_ui(value)
