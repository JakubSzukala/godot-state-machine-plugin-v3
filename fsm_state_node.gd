@tool
class_name FSMStateNode
extends ColorRect

signal transition_drag_started(state_node: FSMStateNode)
signal transition_drag_finished(state_node: FSMStateNode)
signal state_node_position_changed(state_node_name: String, position: Vector2)

var drag_mouse_offset = null
var mouse_inside: bool = false


func set_state_name(new_name: String) -> void:
	$Label.text = new_name
	name = new_name


func get_state_name() -> String:
	return $Label.text


func get_global_center() -> Vector2:
	return global_position + size / 2


func get_position() -> Vector2:
	return position


func as_state_view() -> Dictionary:
	return {
		"name" : get_state_name(),
		"position" : get_position()
	}


func _ready() -> void:
	mouse_entered.connect(func(): mouse_inside = true)
	mouse_exited.connect(func(): mouse_inside = false)


func _input(event: InputEvent):
	# We can move state node in one of two scenarios, where both come down to
	# keeping constant offset from the mouse. Scenarios are as following:
	# 1. We LMB click on the single node and drag
	# 2. We press M and we move all the nodes at once
	if event is InputEventMouseButton:
		# Node drag scenario 1.
		var event_mouse_button: = event as InputEventMouseButton
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT and \
		   event_mouse_button.pressed and mouse_inside:
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
	elif event is InputEventKey:
		# Node drag scenario 2.
		var event_key_button: = event as InputEventKey
		if event.keycode == KEY_M and event.pressed:
			drag_mouse_offset = get_global_mouse_position() - global_position
		else:
			drag_mouse_offset = null


func _process(_delta: float) -> void:
	# Keep constant offset from the mouse while dragging
	if drag_mouse_offset != null:
		global_position = get_global_mouse_position() - drag_mouse_offset
		state_node_position_changed.emit(name, position)
