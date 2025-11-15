class_name Objective
extends Area2D

signal objective_destroyed

@onready var collision_shape := $CollisionShape2D as CollisionShape2D
@onready var anim_sprite := $AnimatedSprite2D as AnimatedSprite2D

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		Global.add_leaked_enemy()
		body.queue_free()
