@tool
class_name FSMDock
extends EditorProperty

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")

var root_control: = Control.new()
var graph: = FsmGraph.new()

var fsm: FSM

# TODO: Allow deletion of transitions from graph
# TODO: On name change, don't get rid of transitions
# TODO: Maybe instead of doing this janky prev/new updates in signals, we could
# do some enum with indication of which property changed, this way we would
# develop some ad hoc communication protocol between FSM entities
# TODO: Add ID mechanism, which may be used by graph to reference states/transitions
# transitions are hard to track because their properties may change, in theory
# arbitraly, so assign ID and track it. Then we can emit transition ID and enum
# with property changed

func _init() -> void:
	add_child(root_control)
	set_bottom_editor(root_control)
	add_focusable(root_control)
	root_control.custom_minimum_size = Vector2(150, 550)
	root_control.set_anchors_and_offsets_preset(LayoutPreset.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_PASS
	root_control.add_child(graph)


func _ready() -> void:
	fsm = get_edited_object()
	fsm.sync()
	graph.state_modified.connect(_on_state_modified)
	graph.transition_property_changed.connect(_on_transition_property_changed)
	graph.transition_deletion_requested.connect(_on_transition_deletion_requested)
	_place()


func _update_property() -> void:
	fsm.sync()
	_clear()
	_place()


## Source of truth are child states in edited FSM
func _place() -> void:
	# First put states
	for state in fsm.transitions:
		graph.place_state_node(state)

	# Then iterate again, now placing transitions between existing nodes
	for state in fsm.transitions:
		for transition in state["transitions"]:
			graph.place_transition_node(transition)


func _clear() -> void:
	graph.clear()


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


func _on_state_modified(full_state_view: Dictionary) -> void:
	for i in range(fsm.transitions.size()):
		if fsm.transitions[i]["name"] == full_state_view["name"]:
			fsm.transitions[i] = full_state_view
			return


func _on_transition_property_changed(id: int, property: String, value: Variant) -> void:
	# That's pretty disgusting...
	for i in range(fsm.transitions.size()):
		for j in range(fsm.transitions[i]["transitions"].size()):
			if fsm.transitions[i]["transitions"][j]["id"] == id:
				fsm.transitions[i]["transitions"][j][property] = value
				return


func _on_transition_deletion_requested(id: int) -> void:
	# Again...
	for i in range(fsm.transitions.size()):
		for j in range(fsm.transitions[i]["transitions"].size()):
			if fsm.transitions[i]["transitions"][j]["id"] == id:
				fsm.transitions[i]["transitions"].remove_at(j)
				return
