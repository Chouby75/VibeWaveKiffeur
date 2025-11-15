extends Tower
class_name GuitareTower

func _ready():
	if Global.guitar_towers_count == 0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.speed *= Global.GUITAR_SPEED_BOOST_FACTOR
	Global.guitar_towers_count += 1
	shooter.get_node("Gun").hide() # Hide the gun
	shooter.set_process(false)
	shooter.set_physics_process(false)

func _exit_tree():
	Global.guitar_towers_count -= 1
	if Global.guitar_towers_count == 0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.speed = enemy.base_speed

func _physics_process(delta: float) -> void:
	# Do nothing to prevent shooting
	pass
