extends Control

var selected_tower: Tower = null

func _ready():
	hide() # Start hidden

func set_tower(tower: Tower):
	print("DEBUG: TowerOptionsPanel.set_tower() called with tower: ", tower.tower_type if tower else "null")
	selected_tower = tower
	if selected_tower:
		# Populate with tower info (placeholder for now)
		$Panel/VBoxContainer/TowerName.text = "Tower: " + selected_tower.tower_type
		show()
		print("DEBUG: TowerOptionsPanel shown for tower: ", selected_tower.tower_type)
	else:
		hide()
		print("DEBUG: TowerOptionsPanel hidden.")

func _on_upgrade_button_pressed():
	print("Upgrade button pressed for tower: ", selected_tower.tower_type)
	# Implement upgrade logic here

func _on_sell_button_pressed():
	if selected_tower:
		print("Sell button pressed for tower: ", selected_tower.tower_type)
		var tower_cost = Global.tower_costs[selected_tower.tower_type]
		var refund_amount = int(tower_cost * 0.70)
		Global.money += refund_amount
		selected_tower.queue_free()
		Global.deselect_all_towers.emit() # Deselect the tower after selling
		print("Sold tower '", selected_tower.tower_type, "' for ", refund_amount, " money.")
