extends Node2D

var current_state: State
var previous_state: State

func _ready() -> void:
	current_state = get_child(0) as State
	previous_state = current_state
	if current_state:
		current_state.enter()
	
func  change_state(state_name: String) -> void:
	var new_state := find_child(state_name, true, false) as State
	
	if new_state == null:
		push_error("State not found: " + state_name)
		return
		
	if new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
		
	previous_state = current_state
	current_state = new_state
	current_state.enter()
