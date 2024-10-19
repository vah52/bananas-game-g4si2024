extends Node2D

# The amount of damager per second, applied per-frame.
@export_range(0.0, 100.0) var damage_rate: float

# The distance in tiles that the damage will be applied. Increments in 1/16ths (one pixel).
@export_range(0.0, 10.0, 1.0/16) var damage_range: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(owner.get_node("Enemies").get_children())
	print("Rate: ", damage_rate)
	print("Range: ", damage_range)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for enemy: Node2D in owner.get_node("Enemies").get_children(false):
		if (enemy.position - position).length() < (damage_range * 16):
			enemy.take_damage(damage_rate * delta)
