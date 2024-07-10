extends Interactable
class_name ScreenInteractable

func interact(_player: Player):
	Global.set_camera_focus.emit(global_position)