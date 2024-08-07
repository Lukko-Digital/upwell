@tool
extends Node2D
class_name SubLevel

@export var parallax_modulate_group: ParallaxModulateGroup

signal parallax_modulate_color_changed(layer: String, modulate: Color)

var last_modulate_data_count: int

func _ready() -> void:
    if parallax_modulate_group == null:
        return
    connect_parallax_modulate_signals()

func _process(_delta: float) -> void:
    if parallax_modulate_group == null:
        return
    if last_modulate_data_count != parallax_modulate_group.modulate_data.size():
        connect_parallax_modulate_signals()


func connect_parallax_modulate_signals():
    for parallax_modulate: ParallaxModulate in parallax_modulate_group.modulate_data:
        parallax_modulate.color_changed.connect(_on_parallax_modulate_color_changed)
    last_modulate_data_count = parallax_modulate_group.modulate_data.size()

func _on_parallax_modulate_color_changed(layer: String, modulate_: Color):
    parallax_modulate_color_changed.emit(layer, modulate_)