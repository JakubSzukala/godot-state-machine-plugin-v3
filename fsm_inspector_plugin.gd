@tool
class_name FsmInspectorPlugin
extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
	var state_machine: = object as FSM
	return state_machine != null


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "transitions":
		add_property_editor(name, FSMDock.new())
		return true
	return false
