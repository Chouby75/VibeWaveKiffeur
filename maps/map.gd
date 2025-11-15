extends Control

@export var starting_money := 5000
@export var max_leaked_enemies = 20

@onready var tilemap := $TileMap as TileMap
@onready var camera := $Camera2D as Camera2D
@onready var objective := $Objective as Objective
@onready var spawner := $Spawner as Spawner

var towers = {
	"gatling": preload("res://entities/towers/gatling_tower.tscn"),
	"cannon": preload("res://entities/towers/cannon_tower.tscn"),
	"missile": preload("res://entities/towers/missile_tower.tscn"),
	"guitare": preload("res://entities/towers/guitare_tower.tscn")
}

var ghost_tower = null
var current_tower_name = ""

func _ready():
	mouse_filter = MOUSE_FILTER_STOP
	Global.tower_drag_started.connect(_on_global_tower_drag_started) 
	
	var map_limits := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	camera.limit_left = map_limits.position.x * tile_size.x
	camera.limit_top = map_limits.position.y * tile_size.y
	camera.limit_right = map_limits.end.x * tile_size.x
	camera.limit_bottom = map_limits.end.y * tile_size.y
	
	var hud = camera.hud as HUD
	Global.money_changed.connect(hud._on_money_changed)
	Global.score_changed.connect(hud._on_score_changed)
	Global.tier_unlocked.connect(hud._on_tier_unlocked)
	Global.enemies_leaked_changed.connect(self._on_enemies_leaked_changed)
	Global.money = starting_money
	spawner.countdown_started.connect(hud._on_spawner_countdown_started)
	spawner.wave_started.connect(hud._on_spawner_wave_started)
	spawner.enemy_spawned.connect(_on_enemy_spawned)

func _input(event):
	if event is InputEventMouseButton:
		
		# --- CAS 1: PLACER UNE TOUR (Ton code est bon, on n'y touche pas) ---
		if ghost_tower and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			
			var tower_name = current_tower_name
			var tower_scene = towers[tower_name]
			
			var tile_coords = tilemap.local_to_map(ghost_tower.position)
			var tile_data = tilemap.get_cell_tile_data(0, tile_coords)
			var placement_area = ghost_tower.get_node("PlacementArea")
			var overlapping_areas = placement_area.get_overlapping_areas()
			
			var can_place = (tile_data == null or tile_data.terrain_set != 0 or tile_data.terrain != 0) and overlapping_areas.size() == 0
			
			if can_place:
				if Global.money >= Global.tower_costs[tower_name]:
					Global.money -= Global.tower_costs[tower_name]
					var tower = tower_scene.instantiate()
					tower.position = ghost_tower.position
					add_child(tower)
				else:
					print("Not enough money")
			else:
				print("Cannot place tower here")
				
			ghost_tower.queue_free()
			ghost_tower = null
			current_tower_name = ""
			
			get_viewport().set_input_as_handled()
			return

		# --- CAS 2: SÉLECTIONNER UNE TOUR (Voici la correction) ---
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var space_state = get_world_2d().direct_space_state
			var world_click_position = get_canvas_transform().affine_inverse() * event.position
			
			var query = PhysicsPointQueryParameters2D.new()
			query.position = world_click_position 
			query.collision_mask = 2
			query.collide_with_bodies = true
			
			var result_array = space_state.intersect_point(query)
			
			# On vérifie si le tableau a au moins un résultat
			if result_array.size() > 0:
				# On prend le premier dictionnaire du tableau
				var first_hit = result_array[0]
				# PUIS on prend le collider de ce dictionnaire
				var clicked_node = first_hit.collider 
			# ▲▲▲▲▲ FIN DE LA CORRECTION ▲▲▲▲▲
				
				if clicked_node is Tower:
					print("Tower clicked: ", clicked_node.name) 
					Global.tower_selection_changed.emit(clicked_node) # Corrected signal emission
					get_viewport().set_input_as_handled()
				else:
					print("Clicked on something else (not a tower)")
					Global.deselect_all_towers.emit()
			else:
				print("Clicked on empty space")
				Global.deselect_all_towers.emit()

func _process(delta):
	if ghost_tower:
		ghost_tower.global_position = get_global_mouse_position()
		var tile_coords = tilemap.local_to_map(ghost_tower.position)
		var tile_data = tilemap.get_cell_tile_data(0, tile_coords)
		var placement_area = ghost_tower.get_node("PlacementArea")
		var overlapping_areas = placement_area.get_overlapping_areas()
		
		if (tile_data == null or tile_data.terrain_set != 0 or tile_data.terrain != 0) and overlapping_areas.size() == 0:
			ghost_tower.modulate = Color(0, 1, 0, 0.5)
		else:
			ghost_tower.modulate = Color(1, 0, 0, 0.5)

func _on_global_tower_drag_started(tower_name: String):
	current_tower_name = tower_name
	ghost_tower = towers[current_tower_name].instantiate()
	ghost_tower.modulate = Color(1, 1, 1, 0.5)
	add_child(ghost_tower)
	
	ghost_tower.input_pickable = false
	ghost_tower.collision_layer = 0
	ghost_tower.collision_mask = 0
	ghost_tower.set_process(false)
	ghost_tower.set_physics_process(false)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null
		current_tower_name = ""
		get_viewport().set_input_as_handled()

func _on_enemies_leaked_changed(count: int):
	if count >= max_leaked_enemies:
		_game_over()

func _on_enemy_spawned(enemy: Enemy):
	enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy):
	Global.money += enemy.kill_reward
	Global.add_score(enemy.base_point_value + enemy.bonus_points)

func _game_over():
	var hud = camera.hud as HUD
	hud.get_node("Menus/GameOver").enable()
	
	hud.get_node("Menus/Pause").queue_free()