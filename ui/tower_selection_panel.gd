extends Control
class_name TowerSelectionPanel

@onready var tower_name_label := $PanelContainer/VBoxContainer/TowerNameLabel as Label

func _ready():
	Global.tower_selection_changed.connect(_on_global_tower_selection_changed)
	hide() # Hide by default

func _on_global_tower_selection_changed(tower: Tower):
	print("TowerSelectionPanel: _on_global_tower_selection_changed received: ", tower.tower_type if tower else "null")
	if tower:
		tower_name_label.text = "Tower: " + tower.tower_type
		show()
		print("TowerSelectionPanel: Showing panel for tower: ", tower.tower_type)
	else:
		tower_name_label.text = ""
		hide()
		print("TowerSelectionPanel: Hiding panel.")
