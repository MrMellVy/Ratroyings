extends RichTextLabel

var default_text = "KEY_CurScore"

func _process(delta: float) -> void:
	var text = str(tr(default_text), str(Global.current_score))
	self.text = (text)
