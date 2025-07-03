@tool
class_name FSMDummyStateNode
extends Control


const DUMMY_STATE_NAME = ""

func get_global_center() -> Vector2:
	return get_global_mouse_position()


func get_state_name() -> String:
	return DUMMY_STATE_NAME
