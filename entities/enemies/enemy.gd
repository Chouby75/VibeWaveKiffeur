class_name Enemy
extends CharacterBody2D

signal enemy_died(enemy: Enemy)
signal enemy_removed # emitted when enemy dies or reaches objective

@export var speed := 150:
	set(value):
		speed = value
		if nav_agent:
			nav_agent.max_speed = speed
@export var rot_speed := 10.0
@export var kill_reward := 100
@export var base_point_value = 10
var bonus_points = 0
var base_speed: int

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var state_machine := $StateMachine as StateMachine
@onready var anim_sprite := $AnimatedSprite2D as AnimatedSprite2D
@onready var collision_shape := $CollisionShape2D as CollisionShape2D
@onready var default_sound := $DefaultSound as AudioStreamPlayer2D
@onready var hud := $UI/EntityHUD as EntityHUD

func add_bonus_points(points: int) -> void:
	bonus_points += points

func _ready() -> void:
	add_to_group("enemies")
	base_speed = speed
	speed = base_speed * pow(Global.GUITAR_SPEED_BOOST_FACTOR, Global.guitar_towers_count)
	var objective: Node2D = $/root/Map/Objective
	nav_agent.set_target_position(objective.global_position)
	nav_agent.max_speed = speed
	
	var shooter = get_shooter()
	if shooter:
		shooter.has_shot.connect(self._on_shooter_has_shot)

func _exit_tree():
	remove_from_group("enemies")


func _calculate_rot(start_rot: float, target_rot: float, _speed: float, delta: float) -> float:
	return lerp_angle(start_rot, target_rot, _speed * delta)


func _move(delta: float) -> void:
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var cur_agent_pos: Vector2 = global_position
	var new_velocity: Vector2 = cur_agent_pos.direction_to(next_path_pos) * speed
	if not nav_agent.avoidance_enabled:
		velocity = new_velocity
		move_and_slide()
	else:
		nav_agent.set_velocity(new_velocity)
	anim_sprite.global_rotation = _calculate_rot(anim_sprite.global_rotation,
			velocity.angle(), rot_speed, delta)
	collision_shape.global_rotation = _calculate_rot(collision_shape.global_rotation,
			velocity.angle(), rot_speed, delta)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

	
func get_shooter() -> Shooter:
	return null


func play_animation(anim_name: String) -> void:
	anim_sprite.play(anim_name)


func die() -> void:
	# Prevent die() from being called multiple times
	if state_machine.current_state and state_machine.current_state.name == "Die":
		return
	state_machine.transition_to("Die")
	collision_shape.set_deferred("disabled", true)
	speed = 0
	nav_agent.set_velocity(Vector2.ZERO)
	anim_sprite.play("die")
	default_sound.stop()
	enemy_died.emit(self)


func _on_animated_sprite_2d_animation_finished():
	if anim_sprite.animation == "die":
		enemy_removed.emit()
		queue_free()


func _on_shooter_has_shot(reload_time):
	hud.animate_reload_bar(reload_time)