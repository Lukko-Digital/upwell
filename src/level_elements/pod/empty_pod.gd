extends Node2D
class_name EmptyPod

@export_range(0, 10) var entry_number: int = 0
@onready var collider: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var left_door: AnimatedSprite2D = $LeftDoor
@onready var right_door: AnimatedSprite2D = $RightDoor
@onready var door_lights: Node2D = $DoorLights

var is_entrace: bool = false

func _ready():
    if Global.pod_position == self:
        open()
    else:
        close()

func open():
    left_door.play("open")
    right_door.play("open")
    collider.disabled = true
    door_lights.show()

func close():
    left_door.play("closed")
    right_door.play("closed")
    collider.disabled = false
    door_lights.hide()