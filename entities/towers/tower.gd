extends StaticBody2D
class_name Tower

signal tower_destroyed
signal tower_selected(tower_instance) # New signal

@export var tower_type: String
@export var detector_color := Color(0, 0, 1.0, 0.1)

var _is_mouse_hovering := false
var is_selected := false # New variable

@onready var collision := $CollisionShape2D as CollisionShape2D
@onready var shooter := $Shooter as Shooter
@onready var detector_shape := $Shooter/Detector/CollisionShape2D as CollisionShape2D
@onready var hud := $UI/EntityHUD as EntityHUD

func _ready():
	set_pickable(true) # Explicitly make the StaticBody2D pickable
	print("Tower '", tower_type, "' _ready() called.")
	Global.tower_selection_changed.connect(_on_global_tower_selection_changed) # Listen to global selection changes
	
	if collision:
		print("CollisionShape2D enabled: ", not collision.disabled)
	else:
		print("CollisionShape2D node not found!")
	
func _process(delta: float) -> void:
	# Debug print to confirm the script is running
	# print("Tower '", tower_type, "' _process is running.")
	pass # Keep this for actual game logic if any

func _physics_process(delta: float) -> void:
	if shooter.targets:
		shooter._rotate_shooter(delta)
		if shooter.should_shoot():
			shooter.shoot()

func _draw() -> void:
	if _is_mouse_hovering:
		draw_circle(Vector2.ZERO, detector_shape.shape.radius, detector_color)
	
	if is_selected:
		# Placeholder for visual selection feedback
		draw_rect(Rect2(-10, -10, 20, 20), Color(1, 1, 0, 0.5), false, 2.0)


func _on_gun_animation_finished():
	if shooter.gun.animation == "die":
		queue_free()


func _on_mouse_entered():
	_is_mouse_hovering = true
	queue_redraw()


func _on_mouse_exited():
	_is_mouse_hovering = false
	queue_redraw()


func _on_shooter_has_shot(reload_time):
	hud.animate_reload_bar(reload_time)

func _update_selection_visuals():
	# For now, just redraw to show the selection rectangle in _draw()
	queue_redraw()
	if is_selected:
		print("Tower selected: ", tower_type)
	else:
		print("Tower deselected: ", tower_type)

func _on_global_tower_selection_changed(selected_tower: Tower):
	is_selected = (selected_tower == self)
	_update_selection_visuals()