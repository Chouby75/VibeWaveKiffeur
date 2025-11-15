extends Node

signal money_changed(money: int)
signal score_changed(score: int)
signal enemies_leaked_changed(count: int)
signal tier_unlocked(tier_name: String)
signal tower_drag_started(tower_name: String)
signal tower_selection_changed(tower: Tower) # New signal
signal deselect_all_towers # New signal

var money: int:
	set(m):
		money = m
		money_changed.emit(money)
var player_score: int:
	set(s):
		player_score = s
		score_changed.emit(player_score)
var enemies_leaked: int:
	set(l):
		enemies_leaked = l
		enemies_leaked_changed.emit(l)
var tower_costs: Dictionary
var guitar_towers_count := 0
const GUITAR_SPEED_BOOST_FACTOR := 1.5

var score_tiers = {
	1000: {"name": "TIER1", "gold": 500, "unlocked": false},
	2500: {"name": "TIER2", "gold": 1000, "unlocked": false},
	5000: {"name": "TIER3", "gold": 2000, "unlocked": false}
}

var selected_tower: Tower = null # New variable

func _ready() -> void:
	var tower_costs_resource = load("res://entities/towers/tower_costs_json.tres")
	tower_costs = tower_costs_resource.data
	reset()
	deselect_all_towers.connect(_on_deselect_all_towers)

func add_score(points: int) -> void:
	player_score += points
	for tier_score in score_tiers:
		if player_score >= tier_score and not score_tiers[tier_score]["unlocked"]:
			money += score_tiers[tier_score]["gold"]
			score_tiers[tier_score]["unlocked"] = true
			tier_unlocked.emit(score_tiers[tier_score]["name"])

func add_leaked_enemy() -> void:
	enemies_leaked += 1

func reset() -> void:
	player_score = 0
	money = 0
	enemies_leaked = 0
	guitar_towers_count = 0
	for tier_score in score_tiers:
		score_tiers[tier_score]["unlocked"] = false
	
	if selected_tower:
		selected_tower.is_selected = false
		selected_tower._update_selection_visuals()
		selected_tower = null
		tower_selection_changed.emit(null)

func update_all_enemies_speed():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.speed = enemy.base_speed * pow(GUITAR_SPEED_BOOST_FACTOR, guitar_towers_count)

func _on_tower_button_drag_started(tower_name: String): # New function
	tower_drag_started.emit(tower_name)

func _on_tower_selected(tower: Tower): # New function
	print("Global: _on_tower_selected received: ", tower.tower_type if tower else "null")
	if selected_tower and selected_tower != tower:
		print("Global: Deselecting previous tower: ", selected_tower.tower_type)
		selected_tower.is_selected = false
		selected_tower._update_selection_visuals()
	
	selected_tower = tower
	print("Global: New selected tower: ", selected_tower.tower_type if selected_tower else "null")
	tower_selection_changed.emit(selected_tower)

func _on_deselect_all_towers(): # New function
	print("Global: _on_deselect_all_towers received.")
	if selected_tower:
		print("Global: Deselecting current tower: ", selected_tower.tower_type)
		selected_tower.is_selected = false
		selected_tower._update_selection_visuals()
		selected_tower = null
		tower_selection_changed.emit(null)
