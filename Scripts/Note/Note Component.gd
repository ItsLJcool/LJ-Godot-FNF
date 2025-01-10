@tool
class_name Note extends Node2D

enum NoteType {
	Default_Note,
	Base_Game,
}

# Using AnimatedSprite2D to allow for people to use animted note textures.
@export var __sprite:AnimatedSprite2D;
@export var sustain:Line2D;
@export var endClipRect:Control;
@export var end:AnimatedSprite2D;

var __strum:StaticArrow;

var strumTime:float = 1000;
var sustainLength:float = 500;

## If botplay should avoid the note
var avoid:bool = false;

var direction:StaticArrow.Direction = StaticArrow.Direction.Left:
	set(value):
		direction = value
		if !Engine.is_editor_hint():
			set_direction();
func set_direction():
	var array = [];
	if (!__strum.muliStrums.has(__strum.strumLine.StrumsAmount)):
		array = [StaticArrow.Direction.Left, StaticArrow.Direction.Down, StaticArrow.Direction.Up, StaticArrow.Direction.Right]
	else:
		array = __strum.muliStrums.get(__strum.strumLine.StrumsAmount)
	
	var strumDir = 0;
	if (direction < array.size()):
		strumDir = array[direction]
	
	__sprite.rotation_degrees = StaticArrow.rotated_direction(strumDir)

var _notePath:String = "res://Scenes/Notes/%s/note.tres";
var noteType:NoteType = NoteType.Default_Note:
	set(value):
		noteType = value;
		__sprite.sprite_frames = load(_notePath % get_noteType());
		__sprite.play("note");
		direction = direction;

func get_noteType():
	return NoteType.keys()[noteType].replace("_", " ");

var canBeHit:bool = false;
var tooLate:bool = false;
var wasGoodHit:bool = false;

var hitWindow:float = 160;
var earlyPressWindow:float = 0.5;
var latePressWindow:float = 1;

func _ready() -> void:
	noteType = noteType;
	if (!Engine.is_editor_hint()):
		endClipRect.clip_contents = true;

func _process(delta: float) -> void:
	if (Engine.is_editor_hint()):
		return;
	#if (!Conductor.song_started):
		#return;

func updateSustain(strum:StaticArrow):
	var lastPoint = sustain.get_point_position(sustain.get_point_count()-1); # me when I LIE TO YOU!!
	var _endSize = end.sprite_frames.get_frame_texture(end.animation, 0);
	
	var lengthPog = (0.45 * round(strum.scrollSpeed * 100) / 100);
	var yVal = 0;
	if position.y < strum.position.y and wasGoodHit:
		yVal = ((sustainLength + (strumTime - Conductor.song_position)) * lengthPog);
		
		sustain.position.y = -(position.y - strum.position.y);
	else:
		yVal = (sustainLength * lengthPog);
		
		sustain.position.y = 0;
	
	yVal -= _endSize.get_height();
	lastPoint.y = yVal;
	
	lastPoint.y = max(lastPoint.y, 0)
	
	sustain.set_point_position(sustain.get_point_count()-1, lastPoint);
	
	endClipRect.position.x = -(_endSize.get_width() * 0.5);
	endClipRect.size.x = _endSize.get_width();
	endClipRect.size.y = yVal + _endSize.get_height();
	
	end.position.x = _endSize.get_width() * 0.5;
	end.position.y = yVal;
