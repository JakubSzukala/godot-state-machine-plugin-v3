@tool
class_name FSMDock
extends EditorProperty

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")

var root_control: = Control.new()
var graph: = FsmGraph.new()

var fsm: FSM

# TODO: _update_property to handle changes from outside
# TODO: Make graph into an interface which will gather scattered data from
# nodes and transitions (their changes in data) and merge them so dock can then
# put them into improved transition data (view and model together)

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
	graph.state_modified.connect(_on_state_modified)
	_place()
	#_place_transitions_nodes()


## Source of truth are child states in edited FSM
func _place() -> void:
	# First put states
	for state in fsm.transitions:
		graph.add_state_node(state)

	# Then iterate again, now placing transitions between existing nodes
	for state in fsm.transitions:
		for transition in state["transitions"]:
			graph.add_transition_node(transition)

#	for state_name in fsm.get_state_names():
#		var state_view = fsm.get_state_view(state_name)
#		if state_view:
#			graph.add_state_node(state_view)
#		else:
#			graph.add_state_node({"name" : state_name, "position" : Vector2.ZERO})


#func _place_transitions_nodes() -> void:
#	# Iterate source of truth - transitions
#	for transition_key in fsm.transitions:
#		# Convert transition to logically equivalent transition view
#		var transition_value = fsm.transitions[transition_key]
#		var ref_trasition_view = _to_transition_view(
#			transition_key,
#			transition_value
#		)
#
#		# This is our default
#		var target_transition_view = ref_trasition_view
#
#		# Check if nodes declared in the transition are children of FSM,
#		# if not update transitions and skip adding it to graph
#		if not _is_transition_view_valid(target_transition_view):
#			fsm.transitions.erase(transition_key)
#			emit_changed(FsmInspectorPlugin.TRANSITIONS, fsm.transitions)
#			continue
#
#		# Check if there is already logically equivalent view defined
#		# in state machine, if there is, choose it
#		var equal_view = _find_logically_equal_transition_view(
#			target_transition_view,
#			fsm.transition_views
#		)
#		if equal_view:
#			target_transition_view = equal_view
#
#		# Either add from default view or from existing view
#		graph.add_transition_node(target_transition_view)


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
		if FsmTransition.logically_equal(target_transition_view, transition_view):
			return transition_view
	return null


func _is_transition_view_valid(transition_view: Dictionary) -> bool:
	return fsm.find_child(transition_view["from"], false, false) != null and \
		fsm.find_child(transition_view["to"], false, false) != null


#func _add_to_fsm(transition_view: Dictionary) -> void:
#	# TODO: Check if fsm doesn't already contain such view/transition
#
#	# Update model
#	var result = _to_transition(transition_view)
#	fsm.transitions[result[0]] = result[1]
#	emit_changed(FsmInspectorPlugin.TRANSITIONS, fsm.transitions)
#
#	# Update view
#	fsm.transition_views.append(transition_view)
#	emit_changed(FsmInspectorPlugin.TRANSITION_VIEWS, fsm.transition_views)
#
#
#func _remove_from_fsm(transition_view: Dictionary) -> void:
#	var result = _to_transition(transition_view)
#	var key = result[0]
#	# Update model
#	if fsm.transitions.has(key):
#		fsm.transitions.erase(key)
#		emit_changed(FsmInspectorPlugin.TRANSITIONS, fsm.transitions)
#
#	# Update view
#	var idx: = fsm.transition_views.find_custom(func(x):
#		return FsmTransition.logically_equal(transition_view, x)
#	)
#	if idx != -1:
#		fsm.transition_views.remove_at(idx)
#		emit_changed(FsmInspectorPlugin.TRANSITION_VIEWS, fsm.transition_views)


func _on_state_modified(full_state_view: Dictionary) -> void:
	for i in range(fsm.transitions.size()):
		if fsm.transitions[i]["name"] == full_state_view["name"]:
			fsm.transitions[i] = full_state_view
			return


#func _on_transition_added(transition_view: Dictionary) -> void:
#	_add_to_fsm(transition_view)
#
#
#func _on_transition_removed(transition_view: Dictionary) -> void:
#	_remove_from_fsm(transition_view)

# TODO: Also save updates to view only
