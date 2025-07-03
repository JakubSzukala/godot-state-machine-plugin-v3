@tool
class_name FSMDock
extends EditorProperty

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")

var root_control: = Control.new()
var graph: FSMGraph = FSMGraph.new()

var fsm: FSM

# TODO: On name change, don't get rid of transitions

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
	_clear()
	fsm.sync()
	_place()


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
