@tool
class_name FSM
extends Node

## {
## 		"" : 
## }
@export var transitions: Dictionary

##
@export var fsm_states_view: Dictionary

## 
@export var transitions_view: Array[Dictionary]


func get_states() -> Array:
	return find_children("*", "FSMState", false, false)


func get_state_names() -> Array:
	var names = []
	for fsm_state in get_states():
		names.append(fsm_state.name)
	return names


func get_state_view_data(fsm_state_name: String):
	if fsm_states_view.has(fsm_state_name):
		return fsm_states_view[fsm_state_name]
	return null
