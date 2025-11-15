extends CanvasLayer

var towers = {
	"gatling": {"scene": preload("res://entities/towers/gatling_tower.tscn"), "icon": preload("res://assets/ui/turret_menu/turret_gatling_icon.png"), "cost": 200},
	"cannon": {"scene": preload("res://entities/towers/cannon_tower.tscn"), "icon": preload("res://assets/ui/turret_menu/turret_single_icon.png"), "cost": 500},
	"missile": {"scene": preload("res://entities/towers/missile_tower.tscn"), "icon": preload("res://assets/ui/turret_menu/turret_missile_icon.png"), "cost": 1000},
	"guitare": {"scene": preload("res://entities/towers/guitare_tower.tscn"), "icon": preload("res://assets/ui/turret_menu/turret_guitare_icon.png"), "cost": 300}
}

@onready var tower_container = $Panel/HBoxContainer

const TowerButton = preload("res://ui/tower_button.gd")

func _ready():
	for tower_name in towers:
		var button = Button.new()
		var tower_data = towers[tower_name]
		button.icon = tower_data.icon
		button.name = tower_name
		
		button.set_script(TowerButton)
		button.tower_name = tower_name
		button.tower_icon = tower_data.icon
		button.drag_started_with_tower.connect(Global._on_tower_button_drag_started) # Connect the signal
		
		tower_container.add_child(button)
