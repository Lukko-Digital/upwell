@tool
extends ArtificialGravity
class_name MapAG

func _process(delta: float) -> void:
	super(delta)
	if not Engine.is_editor_hint():
		visible = Global.pod_has_clicker