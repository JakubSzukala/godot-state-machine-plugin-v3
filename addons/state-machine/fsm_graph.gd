@tool
class_name FsmGraph
extends Control

signal transition_added(transition_view: Dictionary)
signal transition_removed(transition_view: Dictionary)

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")
var fsm_dummy_state_node_scn = preload("res://addons/state-machine/fsm_dummy_state_node.tscn")

var dragging_transition: FsmTransition = null


func add_state_node(state_view: Dictionary) -> void:
	var fsm_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	fsm_state_node.set_state_name(state_view["name"])
	fsm_state_node.position = state_view["position"]
	add_child(fsm_state_node)
	fsm_state_node.transition_drag_started.connect(_on_transition_drag_started)
	fsm_state_node.transition_drag_finished.connect(_on_transition_drag_finished)


func add_transition_node(transition_view: Dictionary) -> void:
	var fsm_transition: FsmTransition = fsm_transition_scn.instantiate()
	var from_node = _get_state_node(transition_view["from"])
	var to_node = _get_state_node(transition_view["to"])
	assert(from_node and to_node)
	fsm_transition.set_from_node(from_node)
	fsm_transition.set_to_node(to_node)
	fsm_transition.set_r_scale(transition_view["r_scale"])
	fsm_transition.transition_changed.connect(_on_transition_changed)
	add_child(fsm_transition)


func get_state_views() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for state in _get_state_nodes():
		var state_view = {
			"name" : state.get_state_name(),
			"position" : state.position
		}
		output.append(state_view)
	return output


func get_transition_views() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for transition in _get_transition_nodes():
		output.append(transition.as_transition_view())
	return output


func _get_state_node(node_name: String) -> FsmStateNode:
	var fsm_state_node: FsmStateNode = get_node(node_name)
	return fsm_state_node


func _get_state_nodes() -> Array:
	return find_children("*", "FsmStateNode", false, false)


func _get_transition_nodes() -> Array:
	return find_children("*", "FsmTransition", false, false)


func _on_transition_drag_started(state_node: FsmStateNode) -> void:
	dragging_transition = fsm_transition_scn.instantiate() as FsmTransition
	var dummy: FSMDummyStateNode = fsm_dummy_state_node_scn.instantiate()
	dragging_transition.set_from_node(state_node)
	dragging_transition.set_to_node(dummy)
	add_child(dragging_transition)
	add_child(dummy)


func _on_transition_drag_finished(state_node: FsmStateNode) -> void:
	dragging_transition.set_to_node(state_node)
	find_children("*", "FSMDummyStateNode", false, false)[0].queue_free()

	# Notify about transition being added
	var transition_view: = dragging_transition.as_transition_view()
	transition_added.emit(transition_view)

	dragging_transition = null


func _on_transition_changed(prev: Dictionary, new: Dictionary) -> void:
	if FsmTransition.logically_equal(prev, new):
		return

	transition_removed.emit(prev)
	transition_added.emit(new)
