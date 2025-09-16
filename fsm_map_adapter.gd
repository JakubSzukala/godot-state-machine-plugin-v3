class_name FSMMapAdapter
extends FSMAdapter

@export var map_handler_0_args_to: String
@export var map_handler_1_args_to: String
@export var map_handler_2_args_to: String
@export var map_handler_3_args_to: String
@export var map_handler_4_args_to: String


func _handler_0_args() -> void:
	if not map_handler_0_args_to.is_empty():
		adapted_signal.emit(map_handler_0_args_to)


func _handler_1_args(_0) -> void:
	if not map_handler_1_args_to.is_empty():
		adapted_signal.emit(map_handler_1_args_to)


func _handler_2_args(_0, _1) -> void:
	if not map_handler_2_args_to.is_empty():
		adapted_signal.emit(map_handler_2_args_to)


func _handler_3_args(_0, _1, _2) -> void:
	if not map_handler_3_args_to.is_empty():
		adapted_signal.emit(map_handler_3_args_to)


func _handler_4_args(_0, _1, _2, _3) -> void:
	if not map_handler_4_args_to.is_empty():
		adapted_signal.emit(map_handler_4_args_to)
