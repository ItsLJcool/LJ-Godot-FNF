extends Node

## self explanatory
var bpm:float = 100:
	set(value):
		bpm_change.emit(value)
		bpm = value
		crochet = ((60 / bpm) * 1000)
		step_crochet = crochet / 4

## beats in milliseconds
var crochet:float = ((60 / bpm) * 1000) # beats in ms

## steps in milliseconds
var step_crochet:float = crochet / 4 # steps in ms

## the current position in the song before it is updated
var _old_song_position:float = 0

## how much progress has been made in the song before it's updated, from 0 to 1
var _old_song_progress:float = 0

## the current position in the song
var song_position:float = 0

## how much progress has been made in the song, from 0 to 1
var song_progress:float = 0

## how long a beat is, in steps
var beat_length:int = 4 # in steps

## how long a section (measure) is, in beats
var section_length:int = 4 # in beats

var cur_step:int = 1
var cur_beat:int = 1
var cur_measure:int = 1

signal step_hit(step:int)
signal beat_hit(beat:int)
signal measure_hit(measure:int)
signal bpm_change(bpm:float)
signal song_start
signal song_progress_update

var paused:bool = false
var song_started:bool = false

var audio_player:AudioStreamPlayer = AudioStreamPlayer.new()
var audio_stream:AudioStream = AudioStream.new():
	set(value):
		audio_stream = value;
		audio_player.stream = audio_stream;

#var song:Song:
	#get: return song
	#set(value):
		#song = value
		#pause()
		#reset()
		#bpm = song.meta.bpm
		#audio_player.stream = song.audio_stream

func _ready() -> void:
	audio_player.name = "SongPlayer"
	add_child(audio_player)
	audio_player.bus = "Music"
	audio_player.finished.connect(finished)
	
func finished():
	print("finished Conductor")
	song_started = false
	paused = true
	song_position = -5000

func _process(delta:float) -> void:
	_old_song_position = song_position
	_old_song_progress = song_progress
	if not paused and not song_started:
		if song_position >= 0:
			song_start.emit()
			play()
		song_position += delta * 1000
	elif not paused and song_started:
		song_position = audio_player.get_playback_position() * 1000

	var old_step:int = cur_step

	cur_step = floor(song_position / step_crochet);
	@warning_ignore("integer_division")
	cur_beat = floor(cur_step / 4);
	@warning_ignore("integer_division")
	cur_measure = floor(cur_beat / 4);

	if old_step != cur_step or cur_step == 1:
		step_hit.emit(cur_step);
		if cur_step % beat_length == 0:
			beat_hit.emit(cur_beat);
		if cur_beat % section_length == 0:
			measure_hit.emit(cur_measure);
	
	if audio_player.stream != null:
		song_progress = clampf((song_position / 1000) / audio_player.stream.get_length(), 0, 1)
		song_progress_update.emit()

func intro(length:int = 4) -> void:
	if length > 0:
		song_started = false
		paused = false
		song_position = -(crochet * length)
	else:
		song_start.emit()
		play()

func play() -> void:
	if audio_player.stream != null:
		song_started = true
		paused = false
		audio_player.play()

func pause() -> void:
	paused = true
	if audio_player.stream != null:
		audio_player.stream_paused = paused

func resume() -> void:
	paused = false
	if audio_player.stream != null:
		audio_player.stream_paused = paused

func reset() -> void:
	song_started = false
	song_position = 0
	audio_player.stream = null
