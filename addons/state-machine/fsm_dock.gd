@tool
class_name FSMDock
extends EditorProperty

var fsm_state_node_scn: = preload("res://fsm_state_node.tscn")

var root_control: = Control.new()
var graph: = FsmGraph.new()

var target: FSM


func _ready() -> void:
	target = get_edited_object()
	for state in get_edited_object().find_children("*", "FSMState", false, false):
		if target.states_view and target.states_view.has(state.name):
			# If state was serialized to states_view, then deserialize it
			graph.add_child(_deserialize_fsm_state_node(target.states_view[state.name]))
		else:
			# Otherwise, create a default node
			graph.add_child(_default_fsm_state_node(state.name))


func _init() -> void:
	add_child(root_control)
	set_bottom_editor(root_control)
	add_focusable(root_control)
	root_control.custom_minimum_size = Vector2(150, 550)
	root_control.set_anchors_and_offsets_preset(LayoutPreset.PRESET_FULL_RECT)
	root_control.add_child(graph)


func _exit_tree() -> void:
	var states_view = {}
	for node in _get_fsm_state_nodes():
		var data = _serialize_fsm_state_node(node)
		states_view[node.get_state_name()] = data
	target.states_view = states_view


func _serialize_fsm_state_node(node: FsmStateNode) -> Dictionary:
	return { "name" : node.get_state_name(), "position" : node.position}


func _deserialize_fsm_state_node(node_data: Dictionary) -> FsmStateNode:
	var fsm_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	fsm_state_node.set_state_name(node_data["name"])
	fsm_state_node.position = node_data["position"]
	return fsm_state_node


func _default_fsm_state_node(node_name: String) -> FsmStateNode:
	var fsm_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	fsm_state_node.set_state_name(node_name)
	fsm_state_node.position = Vector2.ZERO
	return fsm_state_node


func _get_fsm_states() -> Array:
	return get_edited_object().find_children("*", "FSMState")


func _get_fsm_state_nodes() -> Array:
	return graph.find_children("*", "FsmStateNode", false, false)
