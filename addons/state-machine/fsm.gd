@tool
class_name FSM
extends Node

@export var transitions: Array[Dictionary]

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

func get_states() -> Array:
	return find_children("*", "FSMState", false, false)


func get_state_names() -> Array:
	var names = []
	for fsm_state in get_states():
		names.append(fsm_state.name)
	return names

func sync() -> void:
	# I know this is inefficient, but it's the simplest. Sue me bitch
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
		synced.append(result_state_view)
	# Anything else is disbanded
	transitions = synced


# TODO: Connect to child rename signal!!!!!!!!1
func _on_child_entered_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	sync()


func _on_child_exiting_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	sync()
