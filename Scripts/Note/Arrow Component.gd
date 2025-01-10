@tool
class_name StaticArrow extends Node2D

enum StrumType {
	Default_Note,
	#Base_Game,
}

enum Direction {
	Left = 0,
	Down = 1,
	Up = 2,
	Right = 3,
}
static func rotated_direction(dir:Direction):
	match dir:
		Direction.Left:
			return 0;
		Direction.Down:
			return -90;
		Direction.Up:
			return -270;
		Direction.Right:
			return -180;
	return 0;

@export var __sprite:AnimatedSprite2D

var strumLine:StrumLine;

var muliStrums:Dictionary[int, Array] = {
	1: [Direction.Left],
	2: [Direction.Left, Direction.Right],
	3: [Direction.Left, Direction.Down, Direction.Right],
	4: [Direction.Left, Direction.Down, Direction.Up, Direction.Right]
}

var direction:Direction = Direction.Left
func set_direction(strumsAmount:int):
	var array = [];
	if (!muliStrums.has(strumsAmount)):
		array = [Direction.Left, Direction.Down, Direction.Up, Direction.Right]
	else:
		array = muliStrums.get(strumsAmount)
	
	var strumDir = 0;
	if (direction < array.size()):
		strumDir = array[direction]
	direction = strumDir;
	__sprite.rotation_degrees = rotated_direction(strumDir)

var _strumPath:String = "res://Scenes/Notes/%s/arrow.tres";
@export var strumType:StrumType = StrumType.Default_Note:
	set(value):
		strumType = value;
		__sprite.sprite_frames = load(_strumPath % get_strumType());
		__sprite.play("arrow");
		direction = direction;

func get_strumType():
	return StrumType.keys()[strumType].replace("_", " ");


func onGenerate():
	pass


# Note Handling Code

var scrollSpeed:float = 1;

var _notes:Array[Note] = [];
func update_notes():
	if (Engine.is_editor_hint() or !Conductor.song_started):
		return
	
	for note in _notes:
		note.position.x = 0;
		note.position.y = noteTime(note);
		check_note(note);
		if (note.position.y < -5000):
			deleteNote(note);

func noteTime(note:Note):
	return (note.strumTime - Conductor.song_position) * (0.45 * round(scrollSpeed * 100) / 100);

signal noteHit(note:Note)
signal noteMiss(note:Note)
signal noteDelete(note:Note)

func goodNoteHit(note:Note):
	note.wasGoodHit = true;
	note.__sprite.visible = false;
	noteHit.emit(note);

func doNoteMiss(note:Note):
	deleteNote(note);
	noteMiss.emit(note)

var cpu:bool = false;
func check_note(note):
	note.canBeHit = ((note.strumTime + note.sustainLength)  > Conductor.song_position - (note.hitWindow * note.latePressWindow)
		and (note.strumTime) < Conductor.song_position + (note.hitWindow * note.earlyPressWindow));
	
	if ((note.strumTime + note.sustainLength) < Conductor.song_position - note.hitWindow and !note.wasGoodHit):
		note.tooLate = true;

	if (cpu && !note.avoid && !note.wasGoodHit && note.strumTime < Conductor.song_position):
		goodNoteHit(note);

	if (note.wasGoodHit && note.strumTime + (note.sustainLength) < Conductor.song_position):
		deleteNote(note);
		return;
		
	if (note.tooLate):
		if (!cpu):
			doNoteMiss(note);
		else:
			deleteNote(note);
		return;
	
	note.updateSustain(self)

func __noteInput(note:Note):
	if (note.canBeHit and !note.wasGoodHit):
		goodNoteHit(note);
		return true;
	return false;

func addNote(note:Note):
	_notes.push_back(note);
	add_child(note);

func deleteNote(note:Note):
	noteDelete.emit(note);
	_notes.remove_at(_notes.find(note));
	note.queue_free();

func on_input():
	if Engine.is_editor_hint() || cpu:
		return
	
	var action = "NOTE_%s" % Direction.keys()[direction].to_upper()
	if Input.is_action_just_pressed(action):
		var isPressingNote = false;
		for note in _notes:
			if (isPressingNote):
				__noteInput(note);
			else:
				isPressingNote = __noteInput(note);
		var anim = "arrow-";
		if (isPressingNote):
			anim += "confirm";
		else:
			anim += "pressed"
		
		__sprite.play(anim);
	
	if Input.is_action_just_released(action):
		for note in _notes:
			if (note.wasGoodHit):
				note.wasGoodHit = false
		__sprite.play("arrow");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	strumType = strumType;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	on_input()
