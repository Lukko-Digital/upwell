@tool
extends UtilityCanvas
class_name ParallaxCanvas

## If true, setting [parallax_layer] won't automatically set
## [follow_viewport_scale], [layer], and [name]
@export var unique_layer: bool = false

## Sets the [follow_viewport_scale] equal to the value and sets [layer] and
## [name] according to the formula below. Value must be greater than 0.
## Converting to canvas layer number:
## When less than one, subtract 1 from the number and multiply by 100.
## e.g. 0.99 = -1, 0.9 = -10, 0.5 = -50
## When greater than one, multiply by 10. e.g. 1 = 10, 1.5 = 15, 2.1 = 21
@export var parallax_layer: float:
    set(value):
        parallax_layer = value
        update_configuration_warnings()
        
        if unique_layer:
            return
        if value < 1:
            layer = roundi(100.0 * (value - 1.0))
        elif value >= 1:
            layer = roundi(value * 10)
        
        follow_viewport_scale = value
        name = str(layer).replace(".", "_")

## If true, don't apply modulation from sublevel's parallax modulate group
@export var unique_modulate: bool = false

## Treat this as a button and when you click it the sprites get renamed
@export var rename_sprites: bool:
    set(value):
        if value:
            update_sprite_grandchildren_name()

func _ready() -> void:
    move_children()
    follow_viewport_enabled = true
    ## Connect enter tree signals for renaming sprite children
    child_entered_tree.connect(_on_child_entered_tree)
    for child in get_children():
        child.child_entered_tree.connect(_on_grandchild_entered_tree)
    ## Color children
    set_child_modulate()

## Check the [SubLevel] for parallax modulate data, modulate children if name
## matches one of the data entries. Connect to the color changed signal of
## [SubLevel] to keep updating color as it changes
func set_child_modulate():
    if (
        unique_modulate or
        not get_parent() is SubLevel
    ):
        return
    var sublevel: SubLevel = get_parent()
    var modulate_group: ParallaxModulateGroup = sublevel.parallax_modulate_group
    if modulate_group == null:
        return

    for parallax_modulate: ParallaxModulate in modulate_group.modulate_data:
        if name != parallax_modulate.parallax_layer:
            continue
        for child in get_children():
            child.modulate = parallax_modulate.modulate

    sublevel.parallax_modulate_color_changed.connect(_on_parallax_modulate_color_changed)

func update_sprite_grandchildren_name():
    for child in get_children():
        for grandchild in child.get_children():
            if not grandchild is Sprite2D:
                continue
            rename_sprite(grandchild)
    print("Sprites renamed")

## Rename a sprite to [layer]_[texture name]
func rename_sprite(sprite: Sprite2D):
    sprite.name = name + "_" + sprite.texture.resource_path.get_file().get_basename()

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if parallax_layer <= 0:
        warnings.append("Parallax Layer must be greater than 0")

    return warnings

func _on_child_entered_tree(node: Node):
    node.child_entered_tree.connect(_on_grandchild_entered_tree)

func _on_grandchild_entered_tree(node: Node):
    if node is Sprite2D:
        rename_sprite(node)

func _on_parallax_modulate_color_changed(layer_: String, modulate: Color):
    if unique_modulate:
        return
    if name == layer_:
        for child in get_children():
            child.modulate = modulate