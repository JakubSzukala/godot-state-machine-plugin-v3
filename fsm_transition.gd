class_name FsmTransition
extends ColorRect


var drag_mouse_offset = null

@export var from_node: FsmStateNode
@export var to_node: FsmStateNode
var from: Vector2
var from_angle: float
var to: Vector2
var to_angle: float
var center: Vector2
var r: float
var r_scale: float = 1.0:
	set(value):
		if value < 1.0:
			r_scale = 1.0
		else:
			r_scale = value
var rescalable: bool = false


func _ready() -> void:
	focus_entered.connect(func(): rescalable = true)
	focus_exited.connect(func(): rescalable = false)


func _input(event: InputEvent):
	if not rescalable:
		return

	var mouse_button_event: = event as InputEventMouseButton
	if not mouse_button_event:
		return

	# TODO: Adding const value here feels pretty janky, in future we could use
	# some function with very low values near 0.5 and high values further from it
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		r_scale = r_scale + 0.01
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		r_scale = r_scale - 0.01


func _process(_delta: float) -> void:
	from = from_node.global_position
	to = to_node.global_position

	# Calculate radius of a circle encapsulating both points, it may be scaled by user
	r = from.distance_to(to) * 0.5 * r_scale

	# Calculate circle center given two points it has to encompass and radius
	var q = from.distance_to(to)
	var mid = (from + to) / 2
	var x = mid.x + sqrt(pow(r, 2) - pow(q/2, 2)) * (from.y - to.y)/q
	var y = mid.y + sqrt(pow(r, 2) - pow(q/2, 2)) * (to.x - from.x)/q
	center = Vector2(x, y)

	# Express positions in coordinate system with origin at circle center and
	# calculate angle between them, in the same coordinate space
	from_angle = (from - center).angle()
	to_angle = (to - center).angle()

	var mid_angle = 0.5 * (to_angle - from_angle)
	var mid_vec: Vector2 = (from - center)
	mid_vec = mid_vec.rotated(mid_angle)
	global_position = mid_vec + center
	queue_redraw()


func _draw() -> void:
	var angles = _equivalent_positive(from_angle, to_angle)
	draw_arc(center - global_position, r, angles["start"], angles["end"], 1000, Color.AQUAMARINE, 1, true)
	draw_circle(center - global_position, 5, Color.CORAL)


func _equivalent_positive(start: float, end: float) -> Dictionary:
	# Make sure that angles are positive
	if end < 0:
		end = end + 2 * PI
	if from_angle < 0:
		start = start + 2 * PI

	# We always want to draw from "from" to "to" in clockwise direction
	# This ensures consistency:
	# - going from left to right is always upper arc
	# - going from right to left is always bottom arc 
	if start > end:
		end = end + 2 * PI
	return {"start" : start, "end" : end}
