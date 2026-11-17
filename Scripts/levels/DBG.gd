extends Node2D
@onready var world_camera: Camera2D = $WorldCamera
@onready var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if world_camera == null:
		world_camera = get_viewport().get_camera_2d()

	if world_camera == null:
		push_error("No camera found. Check WorldCamera node path.")
		return

	world_camera.make_current()

	if player != null and is_instance_valid(player):
		player.world_camera = world_camera

		var remote := RemoteTransform2D.new()
		player.add_child(remote)
		remote.remote_path = remote.get_path_to(world_camera)
