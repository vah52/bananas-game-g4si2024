extends Node

var round_running: bool = false
var current_round: int = 1

var enemy_scene = preload("res://Entities/Enemy.tscn")

@onready var spawn_timer: Timer = $SpawnTimer
@onready var round_timer: Timer = $RoundTimer
@onready var enemies = owner.get_node("Enemies")

var sum_enemy_difficulty: int
var enemy_difficulties: Array[int] = [1, 2, 4]

func delay(time: float):
	spawn_timer.wait_time = time
	spawn_timer.start()
	return await spawn_timer.timeout


func get_difficulty_score(round: int) -> int:
	return min(int(6 * pow(1.15, round - 1)), 120) # No more than 120 enemies can be spawned


func get_enemy_probabilities(round_number: int) -> Array[float]:
	var bias_factor: float = 1 - exp(-float(round_number) / 25)
	
	var probabilities: Array[float] = Array([], TYPE_FLOAT, "", null)
	probabilities.resize(enemy_difficulties.size())
	
	var total_probability: float = 0
	var cumulative_difficulty: float = 0
	for enemy_level: int in enemy_difficulties.size():
		var this_difficulty: float = float(enemy_difficulties[enemy_level])
		cumulative_difficulty += this_difficulty
		
		var dist = abs(cumulative_difficulty / sum_enemy_difficulty - bias_factor)
		var low_level_weight: float = (1 / bias_factor) * pow(1 / dist, 2)
		var high_level_weight: float = (1 / (1 - bias_factor)) * pow(dist, 2)

		probabilities[enemy_level] = low_level_weight + high_level_weight
		total_probability += probabilities[enemy_level]
	
	# Normalize the probabilities
	for enemy_level: int in enemy_difficulties.size():
		probabilities[enemy_level] /= total_probability
	
	print(probabilities)
	return probabilities


func weighted_random(enemy_probabilities: Array[float]) -> int:
	var number: float = randf()
	var cumulative_weight: float = 0
	for enemy_level: int in enemy_probabilities.size():
		cumulative_weight += enemy_probabilities[enemy_level]
		if cumulative_weight >= number:
			return enemy_level
	
	# This should ideally never be reached, but oh well
	return 0


func on_start_of_round(enemy_count: int) -> void:
	print("Starting wave with n enemies: ", enemy_count)
	EnemyHandler.on_new_round(enemy_count)


func on_end_of_round() -> void:
	Globals.award_budget(current_round * 100)
	current_round += 1


func begin_round(round: int) -> void:
	round_running = true
	print("Beginning Wave: ", round)
	
	var difficulty: int = get_difficulty_score(round)
	
	var enemy_counts: Array[int]= Array([], TYPE_INT, "", null)
	enemy_counts.resize(enemy_difficulties.size())
	
	var total_enemy_count: int = 0
	var enemy_probabilities: Array[float] = get_enemy_probabilities(round)
	while difficulty >= 1:
		var enemy_level: int = weighted_random(enemy_probabilities)
		if enemy_difficulties[enemy_level] <= difficulty:
			difficulty -= enemy_difficulties[enemy_level]
			total_enemy_count += 1
			enemy_counts[enemy_level] += 1
	
	
	if total_enemy_count <= 0:
		pass
		# Vanessa put the end transition here 
	
	
	on_start_of_round(total_enemy_count)
	
	print(enemy_counts)
	var enemy_place: int = 0
	for enemy_level: int in enemy_counts.size():
		for i: int in range(enemy_counts[enemy_level]):
			await delay(0.5)
			EnemyHandler.create_enemy(enemy_level, enemy_place)
			enemy_place += 1
	
	on_end_of_round()
	round_running = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for enemy_level: int in enemy_difficulties.size():
		sum_enemy_difficulty += enemy_difficulties[enemy_level]
	
	begin_round(1)


func _on_start_round_pressed() -> void:
	if not round_running and len(enemies.get_children()) == 0:
		begin_round(current_round)
