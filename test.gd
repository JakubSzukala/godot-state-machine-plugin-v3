extends Node

@export var fsm: FSM

const SWITCH_EVENT = "switch"

func _on_state_switch_timer_timeout() -> void:
	fsm.input_event(SWITCH_EVENT)
