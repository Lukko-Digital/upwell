extends Resource
## Used by the player to remember what clickers to respawn, as clickers are
## despawned when entering the players inventory
class_name ClickerInfo

var home_holder: ClickerHolder

func _init(home_holder_: ClickerHolder) -> void:
    home_holder = home_holder_