class_name FsmStateNode
extends ColorRect

signal transition_add_requested(state_node: FsmStateNode)

var drag_mouse_offset = null


func set_state_name(new_name: String) -> void:
	$VBoxContainer/Label.text = new_name


func get_state_name() -> String:
	return $VBoxContainer/Label.text


func _ready() -> void:
	$VBoxContainer/Button.button_up.connect(func(): transition_add_requested.emit(self))


func _gui_input(event: InputEvent):
	var event_mouse_button: = event as InputEventMouseButton
	if not event_mouse_button:
		return

	# Save offset for window drag, in _process we will adjust position
	# too keep constant offset from the mouse
	if event_mouse_button.button_index == 1 and event_mouse_button.pressed:
		drag_mouse_offset = get_global_mouse_position() - global_position
	else:
		drag_mouse_offset = null


func _process(_delta: float) -> void:
	# Keep constant offset from the mouse while dragging
	if drag_mouse_offset:
		global_position = get_global_mouse_position() - drag_mouse_offset
