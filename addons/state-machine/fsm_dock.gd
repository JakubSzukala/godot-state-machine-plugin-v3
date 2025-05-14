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
	fsm.state_views = graph.get_state_views()
	fsm.transition_views = graph.get_transition_views()


## Source of truth are child states in edited FSM
func _place_state_nodes() -> void:
	for state_name in fsm.get_state_names():
		var state_view = fsm.get_state_view(state_name)
		if state_view:
			graph.add_state_node(state_view)
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
			fsm.transition_views
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
					  transition_views):
	for transition_view in transition_views:
		if _transition_views_logically_eqal(target_transition_view, transition_view):
			return transition_view
	return null


func _transition_views_logically_eqal(fsm_transition_view1, fsm_transition_view2) -> bool:
	return fsm_transition_view1["from"] == fsm_transition_view2["from"] and \
		fsm_transition_view1["event"] == fsm_transition_view2["event"] and \
		fsm_transition_view1["to"] == fsm_transition_view2["to"]


func _on_transition_added(transition_view: Dictionary) -> void:
	var key = transition_view["from"] + "/" + transition_view["event"]
	fsm.transitions[key] = transition_view["to"]
	emit_changed(get_edited_property(), fsm.transitions)


func _on_transition_removed(key: String, value: String) -> void:
	pass
