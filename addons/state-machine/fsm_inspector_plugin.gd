@tool
class_name FsmInspectorPlugin
extends EditorInspectorPlugin


const TRANSITIONS = "transitions"
const STATE_VIEWS = "state_views"
const TRANSITION_VIEWS = "transition_views"


func _can_handle(object: Object) -> bool:
	var state_machine: = object as FSM
	return state_machine != null


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "transitions":
		var properties = [
			TRANSITIONS,
			STATE_VIEWS,
			TRANSITION_VIEWS
		]
		add_property_editor_for_multiple_properties(
			TRANSITIONS,
			properties,
			FSMDock.new()
		)
		return true
	elif name == "state_views":
		return true
	elif name == "transition_views":
		return true
	return false
