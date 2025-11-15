extends Tower
class_name GuitareTower

@export var speed_boost_factor := 1.5

func _on_aura_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.speed *= speed_boost_factor

func _on_aura_body_exited(body: Node2D) -> void:
	if body is Enemy:
		body.speed = body.base_speed