extends Node2D
@onready var selected_camera: Camera2D = $Camera2D
@onready var transition_camera: Camera2D = $TransitionCamera

var TransitionTween: Tween
var TransitionZoomTween: Tween
var TransitionOffsetTween: Tween

func _ready() -> void:
	$TransitionCamera.make_current()
	_change_camera($Camera2D)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		if selected_camera == $Camera2D:
			_change_camera($Camera2D2)
		else:
			_change_camera($Camera2D)

func _change_camera(choose_camera: Camera2D) -> void:
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	var target_transform: Transform2D = choose_camera.global_transform
	TransitionTween.tween_property(transition_camera, "global_transform", target_transform, 0.5).set_trans(Tween.TRANS_SINE)
	
	if TransitionZoomTween:
		TransitionZoomTween.kill()
	TransitionZoomTween = create_tween()
	var target_zoom: Vector2 = choose_camera.zoom
	TransitionZoomTween.tween_property(transition_camera, "zoom", target_zoom, 0.5).set_trans(Tween.TRANS_SINE)
	
	if TransitionOffsetTween:
		TransitionOffsetTween.kill()
	TransitionOffsetTween = create_tween()
	var target_offset: Vector2 = choose_camera.offset
	TransitionOffsetTween.tween_property(transition_camera, "offset", target_offset, 0.5).set_trans(Tween.TRANS_SINE)

	selected_camera = choose_camera
