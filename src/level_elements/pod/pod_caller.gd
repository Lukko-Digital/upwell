extends Interactable
class_name PodCaller

@onready var parent: EmptyPod = get_parent()

func interact(_player: Player):
	Global.call_pod(parent)

func interact_condition(_player: Player) -> bool:
	return not Global.pod_position == parent
