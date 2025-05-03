@tool
class_name FsmGraph
extends Control

var fsm_state_node_scn: = preload("res://addons/state-machine/fsm_state_node.tscn")
var fsm_transition_scn: = preload("res://addons/state-machine/fsm_transition.tscn")
var fsm_dummy_state_node_scn = preload("res://addons/state-machine/fsm_dummy_state_node.tscn")

var dragging_transition: FsmTransition = null


func add_fsm_state_node(node: FsmStateNode) -> void:
	add_child(node)
	node.transition_add_started.connect(_on_transition_add_started)
	node.transition_add_finished.connect(_on_transition_add_finished)


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


func _exit_tree() -> void:
	# TODO: Remove temporary node here if there is one
	pass


# TODO: Rename these events to something like transition_drag_started
# TODO: Maybe rename dummy to something indicating it's role?
func _on_transition_add_started(state_node: FsmStateNode) -> void:
	var fsm_transition = fsm_transition_scn.instantiate() as FsmTransition
	var dummy = fsm_dummy_state_node_scn.instantiate() as FSMDummyStateNode
	fsm_transition.from_node = state_node
	fsm_transition.to_node = dummy
	add_child(fsm_transition)
	add_child(dummy)
	dragging_transition = fsm_transition


func _on_transition_add_finished(state_node: FsmStateNode) -> void:
	dragging_transition.to_node = state_node
	find_children("*", "FSMDummyStateNode", false, false)[0].queue_free()
	dragging_transition = null
