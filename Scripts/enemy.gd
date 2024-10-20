extends Node2D
class_name Enemy

static var path: Path2D
static var path_length: float

var ws: float = 130

@export var level_0_health: float = 50
@export var level_1_health: float = 100
@export var level_2_health: float = 200

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var progress_bar: ProgressBar = $CanvasLayer/ProgressBar
var progress_bar_offset: Vector2

var path_follow: PathFollow2D

var sprite_variant: int
var level_health: Array[int] = [level_0_health, level_1_health, level_2_health]
var current_level: int
var current_health: float
@export var dead: bool = false


static func create(level: int, id: String) -> Node2D:
	var this: Node2D = preload("res://Entities/Enemy.tscn").instantiate()
	this.initialize_params(level, id)
	return this


func initialize_params(level: int, id: String):
	self.name = id
	current_level = level
	
	# Getting random number for variant
	sprite_variant = randi_range(0, 1)

# Adjust level-related stuff
func adjust_to_level(new_level: int):
	current_level = new_level
	current_health = level_health[current_level] + current_health
	sprite.animation = str(sprite_variant) + str(current_level) + "_walk"
	progress_bar.max_value = level_health[current_level]
	progress_bar.value = current_health


func _ready() -> void:
	path = get_tree().get_root().get_node("test_level").get_node("Path2D")
	path_length = path.curve.get_baked_length()
	
	# Initializing object variables
	progress_bar_offset = progress_bar.position
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	path.add_child(path_follow)

	adjust_to_level(current_level)

	# Starting animation
	sprite.play()
	_process(0) # If we dont call this, they will be at the origin for one frame


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dead:
		return
	
	var speed: float = ws * delta
	for node: Node in TowerHandler.slowing_towers:
		var distance: float = (self.position - node.position).length()
		if distance < node.slowing_range:
			speed *= node.slowing_modifier
	

	#path_follow.progress += 250 * speed_modifier

	path_follow.progress += speed

	if path_length - path_follow.progress <= 1:
		handle_death()
		EnemyHandler.register_enemy_finished_path(self.name)
		return
	
	z_index = int(position.y)
	sprite.flip_h = !path_follow.position.x - position.x > 0
	self.position = path_follow.position
	progress_bar.position = get_global_transform_with_canvas().get_origin() + progress_bar_offset


func handle_death():
	get_parent().remove_child(self) # Deletes itself when it dies
	EnemyHandler.register_enemy_death(self.name)


func take_damage(damage: float) -> void:
	current_health -= damage
	progress_bar.value = current_health
	
	if current_health <= 0:
		if(current_level > 0):
			adjust_to_level(current_level - 1)
		elif(!dead):
			sprite.animation = str(sprite_variant) + "0_death"
			sprite.play()
			sprite.animation_finished.connect(handle_death)
			dead = true
