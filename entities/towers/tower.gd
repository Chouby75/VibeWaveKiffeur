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
	print("Tower '", tower_type, "' _ready() called. Connecting tower_selected to Global.")
	tower_selected.connect(Global._on_tower_selected)
	
	if collision:
		print("CollisionShape2D enabled: ", not collision.disabled)
	else:
		print("CollisionShape2D node not found!")
	
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("TOUR CLIQUÉE: ", self.tower_type, " (Input Event received)")
		
		var previously_selected = is_selected
		is_selected = not is_selected
		
		if is_selected:
			print("Tower '", tower_type, "' is now selected. Emitting self.")
			tower_selected.emit(self)
		elif previously_selected and not is_selected: # If it was selected and now it's deselected
			print("Tower '", tower_type, "' is now deselected. Emitting null.")
			tower_selected.emit(null) # Deselect
			
		_update_selection_visuals()
		
		hud.show_options_menu() # Keep this for now, will be adjusted later
		get_viewport().set_input_as_handled()

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
