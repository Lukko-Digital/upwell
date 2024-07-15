extends Resource
## Used by the player to remember what clickers to respawn, as clickers are
## despawned when entering the players inventory
class_name ClickerInfo

var home_holder: ClickerHolder
var parent_node: Node2D

func _init(home_holder_: ClickerHolder, parent_node_: Node2D) -> void:
    home_holder = home_holder_
    parent_node = parent_node_