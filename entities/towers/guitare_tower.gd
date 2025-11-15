extends Tower
class_name GuitareTower

func _ready():
	Global.guitar_towers_count += 1
	Global.update_all_enemies_speed()
	shooter.get_node("Gun").hide() # Hide the gun
	shooter.set_process(false)
	shooter.set_physics_process(false)

func _exit_tree():
	Global.guitar_towers_count -= 1
	Global.update_all_enemies_speed()

func _physics_process(delta: float) -> void:
	# Do nothing to prevent shooting
	pass
