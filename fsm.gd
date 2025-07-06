@tool
class_name FSM
extends Node

@export var transitions: Array[Dictionary]
var runtime_transitions = {}
@export var current_state: FSMState

func _ready() -> void:
	if Engine.is_editor_hint():
		child_entered_tree.connect(_on_child_entered_tree)
		child_exiting_tree.connect(_on_child_exiting_tree)

	# TODO: This should be separate function and should be done in editor
	# And it should map string to node, not string to string
	for state in transitions:
		for transition in state["transitions"]:
			var key = state["name"] + "/" + transition["event"]
			var value = transition["to"]
			runtime_transitions[key] = value


func input_event(event: String) -> void:
	var key = current_state.name + "/" + event
	var new_state_name = runtime_transitions[key]

	if new_state_name == current_state.name:
		return

	for state in get_states():
		if state.name == new_state_name:
			current_state = state


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		current_state.state_process(delta)


func get_states() -> Array:
	return find_children("*", "FSMState", false, false)


func _get_state_names() -> Array:
	var names = []
	for fsm_state in get_states():
		names.append(fsm_state.name)
	return names


func sync() -> void:
	# I know this is inefficient, but it's the simplest. Sue me
	var state_names: = _get_state_names()
	var synced: Array[Dictionary]
	for state in get_states():
		# Fill in default state view
		var result_state_view = {
			"name" : state.name,
			"position" : Vector2.ZERO,
			"transitions" : []
		}

		# If there is such state defined, just copy it and overwrite default
		for state_view in transitions:
			if state_view["name"] == state.name:
				result_state_view = state_view
				# Also sync transitions from this node, check if these are valid
				var synced_transitions = []
				for transition_view in state_view["transitions"]:
					if transition_view["from"] in state_names and \
					   transition_view["to"] in state_names:
						synced_transitions.append(transition_view)
				result_state_view["transitions"] = synced_transitions
		synced.append(result_state_view)
	# Anything else is disbanded
	transitions = synced


func _on_child_entered_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	state_node.renamed.connect(func(): sync())

	sync()


func _on_child_exiting_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	sync()
