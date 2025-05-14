@tool
class_name FsmStateNode
extends ColorRect

signal transition_drag_started(state_node: FsmStateNode)
signal transition_drag_finished(state_node: FsmStateNode)

var drag_mouse_offset = null
var mouse_inside: bool = false


func set_state_name(new_name: String) -> void:
	$Label.text = new_name
	name = new_name


func get_state_name() -> String:
	return name


func get_global_center() -> Vector2:
	return global_position + size / 2


func _ready() -> void:
	mouse_entered.connect(func(): mouse_inside = true)
	mouse_exited.connect(func(): mouse_inside = false)


func _input(event: InputEvent):
	if not mouse_inside:
		return

	var event_mouse_button: = event as InputEventMouseButton
	if not event_mouse_button:
		return

	# Save offset for window drag, in _process we will adjust position
	# too keep constant offset from the mouse
	if event_mouse_button.button_index == MOUSE_BUTTON_LEFT and event_mouse_button.pressed:
		drag_mouse_offset = get_global_mouse_position() - global_position
	else:
		drag_mouse_offset = null

	# Transition add events will be emitted under following conditions:
	# - RMB down and mouse inside -> transition add start
	# - RMB up and mouse inside -> transition add end
	# In case of overlapping nodes, upper layer (graph) will decide which
	# nodes to connect, based on the distance to the centers
	# NOTE: we do this in _input and with parent nodes having events pass through
	# otherwise it won't work
	if event_mouse_button.button_index == MOUSE_BUTTON_RIGHT and \
	   mouse_inside and event_mouse_button.pressed:
		transition_drag_started.emit(self)
	elif event_mouse_button.button_index == MOUSE_BUTTON_RIGHT and \
	   mouse_inside and event_mouse_button.pressed == false:
		transition_drag_finished.emit(self)


func _process(_delta: float) -> void:
	# Keep constant offset from the mouse while dragging
	if drag_mouse_offset:
		global_position = get_global_mouse_position() - drag_mouse_offset
