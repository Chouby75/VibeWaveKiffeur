extends Node

signal money_changed(money: int)
signal score_changed(score: int)
signal enemies_leaked_changed(count: int)
signal tier_unlocked(tier_name: String)

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
		enemies_leaked_changed.emit(enemies_leaked)
var tower_costs: Dictionary

var score_tiers = {
	1000: {"name": "TIER1", "gold": 500, "unlocked": false},
	2500: {"name": "TIER2", "gold": 1000, "unlocked": false},
	5000: {"name": "TIER3", "gold": 2000, "unlocked": false}
}

func _ready() -> void:
	var tower_costs_resource = load("res://entities/towers/tower_costs_json.tres")
	tower_costs = tower_costs_resource.data
	reset()

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
	for tier_score in score_tiers:
		score_tiers[tier_score]["unlocked"] = false
