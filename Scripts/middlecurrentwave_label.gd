extends RichTextLabel


var default_text = "KEY_Zone"

func _process(delta: float) -> void:
	var text = str(tr(default_text), str(Global.current_wave))
	self.text = (text)
