extends RichTextLabel

var default_text = "KEY_ScoreHigh"
var default_text2 = ""

func _process(delta: float) -> void:
	var text = str(tr(default_text), str(Global.high_score), str(default_text2))
	self.text = (text)
