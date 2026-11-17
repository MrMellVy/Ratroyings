extends TextureProgressBar

var parent
var max_value_amount
var min_value_amount

var current_tracked_health: float =  -1.0

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if Global.playerBody != null:
		var actual_max_health = Global.playerBody.health_max
		var actual_health = Global.playerBody.health
		
		if self.max_value != actual_max_health:
			self.max_value = actual_max_health
			current_tracked_health = -1.0
		
		if current_tracked_health == -1.0:
			self.value = actual_health
			current_tracked_health = actual_health
		
		elif current_tracked_health != actual_health:
			var tween = create_tween()
			tween.tween_property(self, "value", actual_health, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			current_tracked_health = actual_health
	
		#if Global.playerBody.health == Global.playerBody.health_max or Global.playerBody.health <= Global.playerBody.health_min:
			#self.visible = false
		#else:
			#self.visible = true
