@tool
class_name FsmGraph
extends Control

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")


func add_fsm_state_node(node: FsmStateNode) -> void:
	add_child(node)
	node.transition_add_started.connect(func(x): print("Transition start: ", x))
	node.transition_add_finished.connect(func(x): print("Transition finished: ", x))


func _ready() -> void:
	pass
	# TODO: This will not be here, you will not be able to add
	# nodes manually - only by adding them as children to FSM
	#var idle_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	#add_child(idle_state_node)
	#idle_state_node.set_state_name("Idle")
	#idle_state_node.transition_add_requested.connect(_on_transition_add_requested)
	#idle_state_node.global_position = Vector2(200, 200)
#
	#var run_state_node: FsmStateNode = fsm_state_node_scn.instantiate()
	#add_child(run_state_node)
	#run_state_node.set_state_name("Run")
	#run_state_node.transition_add_requested.connect(_on_transition_add_requested)
	#run_state_node.global_position = Vector2(550, 500)

func _process(_delta):
	#print("fsm")
	#print(get_children())
	#print(size)
	return


func _on_transition_add_requested(state_node: FsmStateNode) -> void:
	
	print(state_node)
