extends Marker2D

@export var custom_font: Font

func show_damage_label(damage):
	var label = _create_indicator_label(damage)
	add_child(label)
	
	var tween = create_tween()
	var target_position = label.position + Vector2(20, -50)
	
	tween.tween_property(label, "position", target_position, 1.0).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _create_indicator_label(damage) -> Label:
	var newLabel = Label.new()
	
	if damage > 0:
		newLabel.text = "+" + str(damage)
		newLabel.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		newLabel.text = str(damage)
		
		if get_parent().is_in_group("enemies"):
			newLabel.add_theme_color_override("font_color", Color(0.775, 0.0, 0.319, 1.0)) 
		else:
			newLabel.add_theme_color_override("font_color", Color(1.0, 0.357, 0.29, 1.0)) 
		
	newLabel.add_theme_font_size_override("font_size", 24)
	
	if custom_font != null:
		newLabel.add_theme_font_override("font", custom_font)
		
	newLabel.z_index = 100
	newLabel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	newLabel.grow_vertical = Control.GROW_DIRECTION_BOTH
	newLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	return newLabel
