extends ProgressBar

var enemy_parent
var current_tracked_health: float =  -1.0

func _ready() -> void:
	enemy_parent = get_parent()
	
	if enemy_parent != null and "health_max" in enemy_parent:
		self.max_value = enemy_parent.health_max
	
func _process(_delta: float) -> void:
	if enemy_parent != null and "health" in enemy_parent:
		var actual_health = enemy_parent.health

		if current_tracked_health == -1.0:
			self.value = actual_health
			current_tracked_health = actual_health
		
		elif current_tracked_health != actual_health:
			var tween = create_tween()
			tween.tween_property(self, "value", actual_health, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			current_tracked_health = actual_health
		if enemy_parent.health == enemy_parent.health_max or enemy_parent.health <= enemy_parent.health_min:
			self.visible = false
		else:
			self.visible = true
