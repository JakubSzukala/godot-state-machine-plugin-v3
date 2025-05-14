@tool
class_name FsmTransition
extends ColorRect

signal event_name_set(event_name: String)

var from_node: FsmStateNode
var to_node: Node
var r_scale: float = 1.0:
	set(value):
		if value < 1.0:
			r_scale = 1.0
		else:
			r_scale = value
var _from: Vector2
var _to: Vector2
var _center: Vector2
var _r: float
var _rescalable: bool = false


func get_event_name() -> String:
	return $EventName.text


func _ready() -> void:
	focus_entered.connect(func(): _rescalable = true)
	focus_exited.connect(func(): _rescalable = false)
	$EventName.text_set.connect(func(): event_name_set.emit($EventName.text))


func _input(event: InputEvent):
	if not _rescalable:
		return

	var mouse_button_event: = event as InputEventMouseButton
	if not mouse_button_event:
		return

	# TODO: Adding const value here feels pretty janky, in future we could use
	# some function with very low values near 0.5 and high values further _from it
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		r_scale = r_scale + 0.01
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		r_scale = r_scale - 0.01


func _process(_delta: float) -> void:
	if not from_node and not to_node:
		return

	_from = from_node.get_global_center() #from_node.global_position
	_to = to_node.get_global_center() # to_node.global_position

	# Calculate radius of a circle encapsulating both points, it may be scaled by user
	_r = _from.distance_to(_to) * 0.5 * r_scale

	# Calculate circle _center given two points it has _to encompass and radius
	var q = _from.distance_to(_to)
	var mid = (_from + _to) / 2
	var x = mid.x + sqrt(pow(_r, 2) - pow(q/2, 2)) * (_from.y - _to.y)/q
	var y = mid.y + sqrt(pow(_r, 2) - pow(q/2, 2)) * (_to.x - _from.x)/q
	_center = Vector2(x, y)

	# Express positions in coordinate system with origin at circle _center and
	# calculate angle between them, in the same coordinate space. We then
	# calculate vector halfway between these angles and shift it back _to global
	# coordinate system
	var angles = {
		"start" : (_from - _center).angle(),
		"end"   : (_to - _center).angle()
	}
	angles = _equivalent_positive(angles["start"], angles["end"])
	angles = _clockwise(angles["start"], angles["end"])
	var mid_angle = 0.5 * (angles["end"] - angles["start"])
	var mid_vec: Vector2 = (_from - _center)
	mid_vec = mid_vec.rotated(mid_angle)
	global_position = mid_vec + _center - size / 2
	queue_redraw()


func _draw() -> void:
	var angles = {
		"start" : (_from - _center).angle(),
		"end"   : (_to - _center).angle()
	}
	angles = _equivalent_positive(angles["start"], angles["end"])
	angles = _clockwise(angles["start"], angles["end"])
	draw_arc(_center - global_position, _r, angles["start"], angles["end"], 1000, Color.AQUAMARINE, 1, true)
	#draw_circle(_center - global_position, 5, Color.CORAL)


func _equivalent_positive(start: float, end: float) -> Dictionary:
	# Make sure that angles are positive
	if end < 0:
		end = end + 2 * PI
	if start < 0:
		start = start + 2 * PI
	return {"start" : start, "end" : end}


func _clockwise(start: float, end: float) -> Dictionary:
	if start > end:
		end = end + 2 * PI
	return {"start" : start, "end" : end}
