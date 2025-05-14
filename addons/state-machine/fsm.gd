@tool
class_name FSM
extends Node

## {
## 		"" : 
## }
@export var transitions: Dictionary

##
@export var state_views: Array[Dictionary]

## 
@export var transition_views: Array[Dictionary]


func get_states() -> Array:
	return find_children("*", "FSMState", false, false)


func get_state_names() -> Array:
	var names = []
	for fsm_state in get_states():
		names.append(fsm_state.name)
	return names


func get_state_view(state_name: String):
	for state_view in state_views:
		if state_view["name"] == state_name:
			return state_view
	return null
