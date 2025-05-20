@tool
class_name FsmTransition
extends ColorRect

signal transition_changed(prev: Dictionary, new: Dictionary)

var _from_node: FsmStateNode
var _to_node: Node
var _r_scale: float = 1.0:
	set(value):
		if value < 1.0:
			_r_scale = 1.0
		else:
			_r_scale = value
var _from: Vector2
var _to: Vector2
var _center: Vector2
var _r: float
var _rescalable: bool = false
var _prev_event_name: String = ""

# NOTE: We expose so many setters and getters to hide quite tangled ways of getting
# data that we want to expose

func set_from_node(new_node: FsmStateNode) -> void:
	var old = as_transition_view()
	_from_node = new_node
	var new = as_transition_view()
	transition_changed.emit(old, new)


func set_to_node(new_node: Node) -> void:
	var old = as_transition_view()
	_to_node = new_node
	var new = as_transition_view()
	transition_changed.emit(old, new)


func get_from_node_name() -> String:
	if _from_node:
		return _from_node.get_state_name()
	return ""


func set_from_node_name(new_name: String) -> void:
	var old = as_transition_view()
	_from_node.set_state_name(new_name)
	var new = as_transition_view()
	transition_changed.emit(old, new)


func get_event_name() -> String:
	return $EventName.text


func set_event_name(new_name: String) -> void:
	var old = as_transition_view()
	$EventName.text = new_name
	var new = as_transition_view()
	transition_changed.emit(old, new)


func get_to_node_name() -> String:
	if _to_node:
		return _to_node.get_state_name()
	return ""


func set_to_node_name(new_name: String) -> void:
	var old = as_transition_view()
	_to_node.set_state_name(new_name)
	var new = as_transition_view()
	transition_changed.emit(old, new)


func get_r_scale() -> float:
	return _r_scale


func set_r_scale(new_value: float) -> void:
	var old = as_transition_view()
	_r_scale = new_value
	var new = as_transition_view()
	transition_changed.emit(old, new)


func get_prev_event_name() -> String:
	return _prev_event_name


func as_transition_view() -> Dictionary:
	return {
		"from" : get_from_node_name(),
		"event" : get_event_name(),
		"to" : get_to_node_name(),
		"r_scale" : get_r_scale()
	}


static func logically_equal(v1: Dictionary, v2: Dictionary) -> bool:
	return v1["from"] == v2["from"] and \
		v1["event"] == v2["event"] and \
		v1["to"] == v2["to"]


func _ready() -> void:
	focus_entered.connect(func(): _rescalable = true)
	focus_exited.connect(func(): _rescalable = false)
	$EventName.text_changed.connect(_on_event_name_set)


func _input(event: InputEvent):
	if not _rescalable:
		return

	var mouse_button_event: = event as InputEventMouseButton
	if not mouse_button_event:
		return

	# TODO: Adding const value here feels pretty janky, in future we could use
	# some function with very low values near 0.5 and high values further _from it
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_r_scale = _r_scale + 0.01
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_r_scale = _r_scale - 0.01


func _process(_delta: float) -> void:
	if not _from_node and not _to_node:
		return

	_from = _from_node.get_global_center()
	_to = _to_node.get_global_center()

	# Calculate radius of a circle encapsulating both points, it may be scaled by user
	_r = _from.distance_to(_to) * 0.5 * _r_scale

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


func _on_event_name_set() -> void:
	# In here, the difference will be only in event
	var old = as_transition_view()
	var new = as_transition_view()
	old["event"] = _prev_event_name
	_prev_event_name = $EventName.text
	transition_changed.emit(old, new)
