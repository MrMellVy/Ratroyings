extends RichTextLabel


var default_text = "KEY_ScorePrev"
var default_text2 = ""

func _process(delta: float) -> void:
	var text = str(tr(default_text), str(Global.previous_score), str(default_text2))
	self.text = (text)
