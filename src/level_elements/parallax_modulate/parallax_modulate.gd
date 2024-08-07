@tool
extends Resource
class_name ParallaxModulate

signal color_changed(layer: String, modulate: Color)

@export var parallax_layer: String
@export var modulate: Color:
    set(value):
        color_changed.emit(parallax_layer, value)
        modulate = value