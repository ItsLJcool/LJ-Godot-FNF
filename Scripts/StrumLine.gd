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

var notes:Array[Dictionary] = [];
func addNote(note:Note):
	if note.direction >= StrumsAmount:
		return;
	_strums[note.direction].addNote(note);

func _ready() -> void:
	StrumsAmount = StrumsAmount;

func _process(delta: float) -> void:
	
	# Handling Note Movement
	for strum in _strums:
		strum.update_notes();
