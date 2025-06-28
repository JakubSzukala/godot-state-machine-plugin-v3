@tool
class_name FSMGraph
extends Control

signal state_modified(full_state_view: Dictionary)
signal transition_property_changed(id: int, property: String, value: Variant)
signal transition_deletion_requested(id: int)

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")
var fsm_dummy_state_node_scn = preload("res://addons/state-machine/fsm_dummy_state_node.tscn")

var dragging_transition: FSMTransition = null
var dummy: FSMDummyStateNode


func _ready() -> void:
	dummy = fsm_dummy_state_node_scn.instantiate()
	add_child(dummy)


func place_state_node(state_view: Dictionary) -> void:
	var state_node: FSMStateNode = fsm_state_node_scn.instantiate()
	add_child(state_node, true)
	state_node.set_state_name(state_view["name"])
	state_node.position = state_view["position"]
	state_node.transition_drag_started.connect(_on_transition_drag_started)
	state_node.transition_drag_finished.connect(_on_transition_drag_finished)
	state_node.state_node_position_changed.connect(_on_state_node_position_changed)


func place_transition_node(transition_view: Dictionary) -> void:
	var fsm_transition: FSMTransition = fsm_transition_scn.instantiate()
	add_child(fsm_transition)
	var from_node = _get_state_node(transition_view["from"])
	var to_node = _get_state_node(transition_view["to"])
	assert(from_node and to_node)
	fsm_transition.set_id(transition_view["id"])
	fsm_transition.set_from_node(from_node)
	fsm_transition.set_event_name(transition_view["event"])
	fsm_transition.set_to_node(to_node)
	fsm_transition.set_r_scale(transition_view["r_scale"])
	fsm_transition.transition_property_changed.connect(_on_transition_property_changed)
	fsm_transition.deletion_requested.connect(_on_transition_deletion_requested)


func clear() -> void:
	# NOTE: We can't free all children because we also have dummy as a child
	for child in _get_state_nodes():
		child.free()
	for child in _get_transition_nodes():
		child.free()


func _get_state_node(node_name: String) -> FSMStateNode:
	var fsm_state_node: FSMStateNode = get_node(node_name)
	return fsm_state_node


func _get_state_nodes() -> Array:
	return find_children("*", "FSMStateNode", false, false)


func _get_transition_nodes() -> Array:
	return find_children("*", "FSMTransition", false, false)


func _get_transition_node_by_id(id: int) -> FSMTransition:
	for transition in _get_transition_nodes() as Array[FSMTransition]:
		if transition.get_id() == id:
			return transition
	return null


func _get_outgoing_transition_views(node_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for transition in _get_transition_nodes() as Array[FSMTransition]:
		if transition.get_from_node_name() == node_name:
			result.append(transition.as_transition_view())
	return result


func _get_full_state_view(node_name: String) -> Dictionary:
	var node_view = _get_state_node(node_name).as_state_view()
	node_view["transitions"] = _get_outgoing_transition_views(node_view["name"])
	return node_view


func _on_transition_drag_started(state_node: FSMStateNode) -> void:
	# Create transition
	var id = (Time.get_unix_time_from_system() * 1000.0) as int
	dragging_transition = fsm_transition_scn.instantiate() as FSMTransition
	dragging_transition.set_id(id)
	dragging_transition.set_from_node(state_node)
	dragging_transition.set_to_node(dummy)
	dragging_transition.transition_property_changed.connect(_on_transition_property_changed)
	dragging_transition.deletion_requested.connect(_on_transition_deletion_requested)
	add_child(dragging_transition)


func _on_transition_drag_finished(state_node: FSMStateNode) -> void:
	dragging_transition.set_to_node(state_node)

	# Notify inspector plugin that node representation has changed
	var from_node_name = dragging_transition.get_from_node_name()
	state_modified.emit(_get_full_state_view(from_node_name))

	dragging_transition = null


func _input(event: InputEvent) -> void:
	var event_mouse_button: = event as InputEventMouseButton
	if not event_mouse_button:
		return

	# If dragging transition is connected to dummy node at this point, delete it
	# This works because node captures transition drag finish before this is called
	# I am not sure how robust this is
	if _dragging_transition_not_connected(event_mouse_button):
		dragging_transition.queue_free()
		dragging_transition = null


func _dragging_transition_not_connected(event: InputEventMouseButton) -> bool:
	return event.button_index == MOUSE_BUTTON_RIGHT and \
			not event.pressed and \
			dragging_transition and \
			dragging_transition.get_to_node_name() == FSMDummyStateNode.DUMMY_STATE_NAME


func _on_transition_property_changed(id: int, property: String, value: Variant) -> void:
	transition_property_changed.emit(id, property, value)


func _on_transition_deletion_requested(id: int) -> void:
	var transition: = _get_transition_node_by_id(id)
	transition.queue_free()
	transition_deletion_requested.emit(id)


func _on_state_node_position_changed(state_node_name: String, _position: Vector2) -> void:
	state_modified.emit(_get_full_state_view(state_node_name))
