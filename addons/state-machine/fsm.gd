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


# TODO: Fsm should ideally update plugin about addition/removal of states
# although this should not be major issue as removing node usually means clicking
# out of FSM which will later start whole node placing process over again
# TODO: Connect to child rename signal!!!!!!!!1
func _on_child_entered_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	transitions.append({
		"name" : state_node.name,
		"position" : Vector2.ZERO,
		"transitions" : []
	})


func _on_child_exiting_tree(node: Node) -> void:
	var state_node: = node as FSMState
	if not state_node:
		return

	for i in range(transitions.size()):
		if transitions[i]["name"] == state_node.name:
			transitions.remove_at(i)
