extends AudioStreamPlayer

@onready var dummy_player = AudioStreamPlayer.new()
@onready var GO_player = AudioStreamPlayer.new()

#GO means GameOver, which mean it only play when the player defeated. Ok.

var fading = false
var crossfade_time: float = 5.0
var fading_onstart: bool = true 
var is_game_paused: bool = false
var ducked_volume_db: float = -15.0

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	bus = "BGM"
	add_child(dummy_player)
	add_child(GO_player)
	volume_db = -80.0
	play()

func set_pause_state(paused: bool) -> void:
	is_game_paused = paused
	if paused and fading:
		volume_db = 0
		dummy_player.volume_db = -60
		stream = dummy_player.stream
		play(dummy_player.get_playback_position())
		dummy_player.stop()
		fading = false
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if paused:
		tween.tween_property(self, "volume_db", ducked_volume_db, 0.3)
		tween.parallel().tween_property(dummy_player, "volume_db", ducked_volume_db, 0.3)
	else:
		tween.tween_property(self, "volume_db", 0.0, 0.3)
		tween.parallel().tween_property(dummy_player, "volume_db", -60, 0.3)
	
func play_defeated():
	stop()
	dummy_player.stop()
	GO_player.stream = load("res://Assets/Audio/SFX/Gameovertheme.wav")
	GO_player.volume_db = 0.0
	GO_player.play()
	
func _process(delta: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus)
	var bus_vol = AudioServer.get_bus_volume_db(bus_idx)
	var is_muted = bus_vol <= -80.0
	
	if is_game_paused:
		return
	
	if fading_onstart:
		if is_muted:
			volume_db = -80.0
			fading_onstart = false
		else:
			#volume_db += 30*delta #simple math
			var fade_speed_onstart = 80.0 / crossfade_time
			volume_db += fade_speed_onstart * delta
			if volume_db >= 0.0:
				volume_db = 0
				fading_onstart = false
		
	if fading:
		if is_muted:
			volume_db = -80.0
			dummy_player.volume_db = -80.0
			stream = dummy_player.stream
			play(dummy_player.get_playback_position())
			dummy_player.stop()
			fading = false
		else:
			var fade_speed = 60.0 / crossfade_time
			volume_db -= fade_speed * delta
			dummy_player.volume_db += fade_speed * delta

			if dummy_player.volume_db >= 0:
				volume_db = 0
				dummy_player.volume_db = -60
				
				stream = dummy_player.stream
				play(dummy_player.get_playback_position())
				
				dummy_player.stop()
				fading = false
			
var retry_themes = {
	"Retry": {
		"intro": "res://Assets/Audio/Musics/Original/Gameovertheme_2.ogg",
		"loop": "res://Assets/Audio/Musics/Original/Gameovertheme_2ExtLoop.ogg"
	}
}
var next_loop_path: String = ""
	

func play_retry_music(theme_name: String = "Retry"):
	GO_player.stop() 
	next_loop_path = retry_themes[theme_name]["loop"]
	if not GO_player.finished.is_connected(_on_intro_finished):
		GO_player.finished.connect(_on_intro_finished)
	GO_player.stream = load(retry_themes[theme_name]["intro"])
	GO_player.play()
	
#This func for looping the song if you have a second song that just only for the loop part.
func _on_intro_finished():
	GO_player.finished.disconnect(_on_intro_finished)
	stream = load(next_loop_path)
	volume_db = 0.0
	play()

func play_BGM(BGM_name) -> void:
	GO_player.stop()
	if GO_player.finished.is_connected(_on_intro_finished):
		GO_player.finished.disconnect(_on_intro_finished)
		
	dummy_player.stream = load("res://Assets/Audio/Musics/" + BGM_name + ".ogg")
	dummy_player.volume_db = -60
	dummy_player.play()
	fading = true
