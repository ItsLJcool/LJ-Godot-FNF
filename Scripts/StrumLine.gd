@tool
class_name StrumLine extends Node2D

signal onNoteHit(strumline:StrumLine, strum:StaticArrow, note:Note)
func noteHitEvent(note:Note):
	onNoteHit.emit(self, _strums[note.direction], note);

signal onNoteMiss(strumline:StrumLine, strum:StaticArrow, note:Note)
func noteMissEvent(note:Note):
	onNoteMiss.emit(self, _strums[note.direction], note);

@export var isPlayer:bool = false;

var scrollSpeed:float = 4;

const _max_strums:int = 4;
@export_range(1, _max_strums) var StrumsAmount:int = 4:
	set(value):
		StrumsAmount = value;
		instanceArrows();

var path:String = "res://Scenes/Notes/%s/arrow.tscn";

# Define the fnf stuff
var _strums:Array = [];

func instanceArrows():
	for item in _strums:
		item.queue_free();
	_strums = []
	
	# TODO: Make the Default Note not hardcoded
	var strumScene = load((path % "Default Note"))
	for idx in range(0, StrumsAmount):
		var instance_strum = strumScene.instantiate()
		instance_strum.direction = (idx);
		instance_strum.set_direction(StrumsAmount);
		instance_strum.strumLine = self;
		instance_strum.position.x += (120 * (idx))
		instance_strum.cpu = !isPlayer;
		
		instance_strum.scrollSpeed = scrollSpeed;
		
		instance_strum.connect("noteHit", noteHitEvent)
		instance_strum.connect("noteMiss", noteMissEvent)
		_strums.push_back(instance_strum)
		add_child(instance_strum)
	
	center_origin()

func center_origin():
	if _strums.size() == 0:
		return

	var centroid = Vector2.ZERO
	for strum in _strums:
		centroid += strum.position
	centroid /= _strums.size()

	for strum in _strums:
		strum.position -= centroid

func __addNote(noteData:Dictionary):
	var strum = _strums[noteData.direction];
	var note = noteTemp.instantiate();
	note.__strum = strum;
	note.direction = noteData.direction;
	note.strumTime = noteData.strumTime;
	note.sustainLength = noteData.sustainLength;
	strum.addNote(note);

var notes:Array[Dictionary] = [];
func addNotes(noteData:Array):
	for data in noteData:
		if (data.direction >= StrumsAmount):
			continue;
		notes.push_back(data);
	pass

func _ready() -> void:
	StrumsAmount = StrumsAmount;

var noteTemp = load("res://Scenes/Notes/Default Note/note.tscn")
func _process(delta: float) -> void:
	if Engine.is_editor_hint() || !Conductor.song_started:
		return;
	
	# Implementing the funny
	var idx = notes.size()-1;
	#print("Size: ", notes.size())
	while(idx >= 0):
		var data = notes[idx]
		var spawnTime = (data.strumTime - Conductor.song_position)
		if (spawnTime < 1500):
			__addNote(data);
			notes.remove_at(idx)
		idx -= 1;
	#for data in notes:
	
	# Handling Note Movement
	for strum in _strums:
		strum.update_notes();
