@tool
class_name FSMDock
extends EditorProperty

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")

var root_control: = Control.new()
var graph: = FsmGraph.new()

var fsm: FSM

# TODO: _update_property to handle changes from outside

func _init() -> void:
	add_child(root_control)
	set_bottom_editor(root_control)
	add_focusable(root_control)
	root_control.custom_minimum_size = Vector2(150, 550)
	root_control.set_anchors_and_offsets_preset(LayoutPreset.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_PASS;
	root_control.add_child(graph)


func _ready() -> void:
	fsm = get_edited_object()
	graph.transition_added.connect(_on_transition_added)
	graph.transition_removed.connect(_on_transition_removed)
	_place_state_nodes()
	_place_transitions_nodes()


func _exit_tree() -> void:
	# TODO: Remove these deserialize functions and move their content to graph.gd
	var states_view = {}
	for node in graph.get_state_nodes():
		var data = _serialize_fsm_state_node(node)
		states_view[node.get_state_name()] = data
	fsm.fsm_states_view = states_view

	var transitions_view: Array[Dictionary] = []
	for transition in graph.get_transition_nodes():
		var data = _serialize_fsm_transition(transition)
		transitions_view.push_back(data)
	fsm.transitions_view = transitions_view


func _serialize_fsm_state_node(node: FsmStateNode) -> Dictionary:
	return {
		"name" : node.get_state_name(),
		"position" : node.position
	}


func _default_fsm_state_node(node_name: String) -> FsmStateNode:
	var fsm_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	fsm_state_node.set_state_name(node_name)
	fsm_state_node.position = Vector2.ZERO
	return fsm_state_node


func _serialize_fsm_transition(transition: FsmTransition) -> Dictionary:
	return {
		"from" : transition.from_node.get_state_name(),
		"event" : transition.get_event_name(),
		"to" : transition.to_node.get_state_name(),
		"r_scale" : transition.r_scale
	}


## Source of truth are child states in edited FSM
func _place_state_nodes() -> void:
	for state_name in fsm.get_state_names():
		var fsm_state_view_data = fsm.get_state_view_data(state_name)
		if fsm_state_view_data:
			graph.add_state_node(fsm_state_view_data)
		else:
			graph.add_state_node({"name" : state_name, "position" : Vector2.ZERO})


func _place_transitions_nodes() -> void:
	# Iterate source of truth - transitions
	for transition_key in fsm.transitions:
		# Convert transition to logically equivalent transition view
		var transition_value = fsm.transitions[transition_key]
		var ref_trasition_view = _to_transition_view(
			transition_key,
			transition_value
		)

		# This is our default
		var target_transition_view = ref_trasition_view

		# Check if there is already logically equivalent view defined
		# in state machine, if there is, choose it
		var equal_view = _find_logically_equal_transition_view(
			target_transition_view,
			fsm.transitions_view
		)
		if equal_view:
			target_transition_view = equal_view

		# Either add from default view or from existing view
		graph.add_transition_node(target_transition_view)


## Conversion from transtion to transition view. Note r_scale is always 1.0,
## because that information is not contained inside transition
func _to_transition_view(transition_key: String, transition_value: String) -> Dictionary:
	var split = transition_key.split("/")
	var from_node_name: String = split[0]
	var event_name: String = split[1]
	var to_node_name: String = transition_value
	return {
		"from" : from_node_name,
		"event" : event_name,
		"to" : to_node_name,
		"r_scale" : 1.0
	}


## Convert from view to transition. Note that this is lossy - we lose information
## about r_scale, as it is not contained inside transition
func _to_transition(transition_view: Dictionary) -> Array:
	var key = transition_view["from"] + "/" + transition_view["event"]
	var value = transition_view["to"]
	return [key, value]


func _find_logically_equal_transition_view(target_transition_view: Dictionary,
					  #transition_views: Array[Dictionary]):
					  transition_views):
	for transition_view in transition_views:
		if _transition_views_logically_eqal(target_transition_view, transition_view):
			return transition_view
	return null


func _transition_views_logically_eqal(fsm_transition_view1, fsm_transition_view2) -> bool:
	return fsm_transition_view1["from"] == fsm_transition_view2["from"] and \
		fsm_transition_view1["event"] == fsm_transition_view2["event"] and \
		fsm_transition_view1["to"] == fsm_transition_view2["to"]


func _on_transition_added(key: String, value: String) -> void:
	# Check if identical existing transition doesn't already exist. This
	# should never happen so we assert it
	assert(!(fsm.transitions.has(key) and fsm.transitions[key] == value))
	fsm.transitions[key] = value
	emit_changed(get_edited_property(), fsm.transitions)


func _on_transition_removed(key: String, value: String) -> void:
	pass
