extends Node2D

var temp_filepath:String = "res://Songs/%s/audio/";
var temp_chartPath:String = "res://Songs/%s/charts/"

var songName_temp:String = "protonated-water-fart";
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
	var noteTemp = load("res://Scenes/Notes/Default Note/note.tscn")
	for idx in range(0, strumlinesInGame.size()):
		var strumline = strumlinesInGame[idx];
		strumline.scrollSpeed = json.scrollSpeed
		strumline.instanceArrows();
		strumline.connect("onNoteHit", onStrumsHit);
				
		var notes = strumLines[idx].notes;
		for data in notes:
			var note = noteTemp.instantiate();
			note.strumTime = data.time;
			note.direction = data.id;
			note.sustainLength = data.sLen;
			strumline.addNote(note);

var cpu_note_bounce = [null, null, null, null]
var player_note_bounce = [null, null, null, null]

var cpu_note_move = [null, null, null, null]
var player_note_move= [null, null, null, null]
func onStrumsHit(strumline:StrumLine, strum:StaticArrow, note:Note):
	var strumsinGame = get_strumlines();
	
	var movingX = 5
	var bounce = cpu_note_bounce;
	var move = cpu_note_move
	if (strumline == strumsinGame[1]):
		bounce = player_note_bounce;
		move = player_note_move;
		movingX = -5;
	movingX *= 2
	if move[note.direction]: move[note.direction].kill()
	move[note.direction] = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	move[note.direction].tween_property(strum, "position:x", strum.position.x + movingX, 0.5)
	
	#strum.position.x += movingX;
	if bounce[note.direction]: bounce[note.direction].kill()
	bounce[note.direction] = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)

	strum.position.y -= 14;
	bounce[note.direction].tween_property(strum, "position:y", 0, 0.35)

func get_strumlines():
	var data:Array = [];
	for child in self.get_children():
		if child is StrumLine:
			data.push_back(child)
	return data;
