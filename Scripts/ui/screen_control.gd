extends OptionButton
@onready var screen_control_option_button: OptionButton = $"."

func _ready() -> void:
	if not item_selected.is_connected(_on_item_selected):
		item_selected.connect(_on_item_selected)
	
	if item_count == 0:
		add_item("Windowed", 0)
		add_item("Fullscreeen", 1)
		add_item("Exclusive Fullscreen", 2)
	
	_show_item_selected()
	var popup = screen_control_option_button.get_popup()
	var my_custom_font = screen_control_option_button.get_theme_font("font")
	popup.add_theme_font_override("font", my_custom_font)
	popup.add_theme_font_size_override("font_size", 18)
	
func _on_item_selected(index: int) -> void:
	var window_modes = [
		DisplayServer.WINDOW_MODE_WINDOWED,
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	]
	
	if index >= 0 and index < window_modes.size():
		DisplayServer.window_set_mode(window_modes[index])

func _show_item_selected() -> void:
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED:
			selected = 0
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			selected = 1
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			selected = 2
		_:
			selected = 0
