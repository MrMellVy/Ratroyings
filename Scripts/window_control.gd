extends OptionButton

var size_names = ["Small", "Medium", "Maximazed"]
var size_values = [
	Vector2i(640, 360),
	Vector2i(1280,720),
	Vector2i(1920,1080)
]

func _ready() -> void:
	if not item_selected.is_connected(_on_item_selected):
		item_selected.connect(_on_item_selected)
	
	if item_count == 0:
		for i in size_names.size():
			add_item(size_names[i], i)
	
	_show_item_selected()


func _on_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var screen_size = DisplayServer.screen_get_size()
	var new_size = size_values[index]
	
	new_size.x = min(new_size.x, screen_size.x)
	new_size.y = min(new_size.y, screen_size.y - 60)

	get_window().size = new_size
	get_window().move_to_center()
	
	var win = get_window()
	if win.position.y < 40:
		win.position.y = 40

func _show_item_selected() -> void:
	var current_size = get_window().size
	selected = 1
	
	for i in size_values.size():
		if size_values[i] == current_size:
			selected = i
			break
