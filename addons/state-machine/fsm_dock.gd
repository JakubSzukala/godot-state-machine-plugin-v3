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


func _update_property() -> void:
	# TODO
	print("Updating property from outside")


## Source of truth are child states in edited FSM
func _place() -> void:
	# First put states
	for state in fsm.transitions:
		graph.add_state_node(state)

	# Then iterate again, now placing transitions between existing nodes
	for state in fsm.transitions:
		for transition in state["transitions"]:
			graph.add_transition_node(transition)


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
