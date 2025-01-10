extends Node2D

var temp_filepath:String = "res://Songs/%s/audio/";
var temp_chartPath:String = "res://Songs/%s/charts/"

var songName_temp:String = "hello";
var temp_diff:String = "hard";

var vocal_player:AudioStreamPlayer = AudioStreamPlayer.new()

func startSong() -> void:
	Conductor.audio_stream = load((temp_filepath % songName_temp) + "Inst.ogg")
	vocal_player.stream = load((temp_filepath % songName_temp) + "Voices.ogg")
	add_child(vocal_player)
	
	vocal_player.play()
	Conductor.play()

func _ready() -> void:
	tempChart();
	startSong();


func tempChart():
	var filePath = ((temp_chartPath % songName_temp) + ("%s.json" % temp_diff))
	if (!FileAccess.file_exists(filePath)):
		print("Path doesn't exist: ", filePath)
		return;
	var jsonString = FileAccess.open(filePath, FileAccess.READ)
	var json = JSON.parse_string(jsonString.get_as_text())
	if (!json is Dictionary):
		print("Error reading file")
		return
	
	var strumLines = json.strumLines;
	
	var strumlinesInGame = get_strumlines();
	for idx in range(0, strumlinesInGame.size()):
		var strumline = strumlinesInGame[idx];
		strumline.scrollSpeed = json.scrollSpeed
		strumline.instanceArrows();
		strumline.connect("onNoteHit", onStrumsHit);
				
		var notes = strumLines[idx].notes;
		var __notes:Array[Dictionary] = []
		for data in notes:
			var noteData:Dictionary = {
				"strumTime": data.time,
				"sustainLength": data.sLen,
				"direction": data.id,
			}
			__notes.push_back(noteData)
		strumline.addNotes(__notes)

var cpu_note_bounce = [null, null, null, null]
var player_note_bounce = [null, null, null, null]
func onStrumsHit(strumline:StrumLine, strum:StaticArrow, note:Note):
	var strumsinGame = get_strumlines();
	
	var bounce = cpu_note_bounce;
	if (strumline == strumsinGame[1]):
		bounce = player_note_bounce;
	
	#strum.position.x += movingX;
	if bounce[note.direction]: bounce[note.direction].kill()
	bounce[note.direction] = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

	strum.position.y -= 7;
	if (strum.position.y < -50):
		strum.position.y = -50
	bounce[note.direction].tween_property(strum, "position:y", 0, 0.35)

func get_strumlines():
	var data:Array = [];
	for child in self.get_children():
		if child is StrumLine:
			data.push_back(child)
	return data;
