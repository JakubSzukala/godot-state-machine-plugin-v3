@tool
class_name FSMTransition
extends ColorRect

signal transition_property_changed(id: int, property: String, value: Variant)
signal deletion_requested(id: int)

var _id: int
var _from_node: FSMStateNode
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
var _angles: Dictionary
var _dash_shift: float = 0.0
const _dash_increment = 0.1

# NOTE: We expose so many setters and getters to hide quite tangled ways of getting
# data that we want to expose and to monitor changes to properties

func _ready() -> void:
	$EventName.text_changed.connect(_on_event_name_set)


func set_id(id: int) -> void:
	_id = id


func get_id() -> int:
	return _id


func set_from_node(new_node: FSMStateNode) -> void:
	_from_node = new_node
	transition_property_changed.emit(_id, "from", _from_node.get_state_name())


func set_to_node(new_node) -> void:
	_to_node = new_node
	transition_property_changed.emit(_id, "to", _to_node.get_state_name())


func get_from_node_name() -> String:
	if _from_node:
		return _from_node.get_state_name()
	return ""


func set_from_node_name(new_name: String) -> void:
	_from_node.set_state_name(new_name)
	transition_property_changed.emit(_id, "from", _from_node.get_state_name())


func get_event_name() -> String:
	return $EventName.text


func set_event_name(new_name: String) -> void:
	$EventName.text = new_name
	transition_property_changed.emit(_id, "event", get_event_name())


func get_to_node_name() -> String:
	if _to_node:
		return _to_node.get_state_name()
	return ""


func set_to_node_name(new_name: String) -> void:
	_to_node.set_state_name(new_name)
	transition_property_changed.emit(_id, "to", _to_node.get_state_name())


func get_r_scale() -> float:
	return _r_scale


func set_r_scale(new_value: float) -> void:
	_r_scale = new_value
	transition_property_changed.emit(_id, "to", _r_scale)


func as_transition_view() -> Dictionary:
	return {
		"id" : get_id(),
		"from" : get_from_node_name(),
		"event" : get_event_name(),
		"to" : get_to_node_name(),
		"r_scale" : get_r_scale()
	}


func _input(event: InputEvent):
	if not has_focus():
		return

	# Handle deletion request
	var keyboard_event: = event as InputEventKey
	if keyboard_event and keyboard_event.keycode == KEY_DELETE:
		# NOTE: If we don't mark it as handled it will be propagated to Node Tree
		# UI and editor will try to delete FSM node
		get_viewport().set_input_as_handled()
		deletion_requested.emit(_id)


	# Handle radius resize
	var mouse_button_event: = event as InputEventMouseButton
	if mouse_button_event:
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
	_angles = {
		"start" : (_from - _center).angle(),
		"end"   : (_to - _center).angle()
	}
	_angles = _equivalent_positive(_angles["start"], _angles["end"])
	_angles = _clockwise(_angles["start"], _angles["end"])
	var mid_angle = 0.5 * (_angles["end"] - _angles["start"])
	var mid_vec: Vector2 = (_from - _center)
	mid_vec = mid_vec.rotated(mid_angle)
	global_position = mid_vec + _center - size / 2

	# TODO: This is unsynchronized between transitions, which looks not great,
	# maybe in the future we could solve that
	# Advance dash
	_angles["dash_start"] = _angles["start"] + _dash_shift - 1
	_angles["dash_end"] = _angles["start"] + _dash_shift

	# Clip it to ends of transition arc
	_angles["dash_start"] = max(_angles["dash_start"], _angles["start"])
	_angles["dash_start"] = min(_angles["dash_start"], _angles["end"])
	_angles["dash_end"] = max(_angles["dash_end"], _angles["start"])
	_angles["dash_end"] = min(_angles["dash_end"], _angles["end"])
	
	# Don't grow shift to infinity
	_dash_shift += _dash_increment
	if _dash_shift >= 2 * PI:
		_dash_shift -= (2 * PI)

	queue_redraw()


func _draw() -> void:
	if _angles.has("start") and _angles.has("end"):
		draw_arc(_center - global_position, _r, _angles["start"], _angles["end"],
				1000, Color.AQUAMARINE, 1, true)
	if _angles.has("dash_start") and _angles.has("dash_end"):
		draw_arc(_center - global_position, _r, _angles["dash_start"], _angles["dash_end"],
				1000, Color.INDIGO, 1, true)


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
	transition_property_changed.emit(_id, "event", get_event_name())
