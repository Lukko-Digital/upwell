extends Control

@export var inventory = [{"name": "fuel", "count": 100, "texture": Color.GRAY}, {"name": "food", "count": 10, "texture": Color.GREEN},null, null, null, null, null, null, null]

@onready var grid_slots = $GridContainer.get_children()

func _ready():
    for i in range(len(grid_slots)):
        grid_slots[i] = grid_slots[i].get_child(0)
        grid_slots[i].update(inventory[i])

func swap(i: int, j: int):
    var _temp = inventory[i]
    inventory[i] = inventory[j]
    inventory[j] = _temp

    grid_slots[i].update(inventory[i])
    grid_slots[j].update(inventory[j])
