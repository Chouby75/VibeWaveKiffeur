extends Button

signal drag_started_with_tower(tower_name: String)

var tower_name: String
var tower_icon: Texture

func _get_drag_data(position):
	print("Drag started for tower: ", tower_name)
	drag_started_with_tower.emit(tower_name)
	var drag_data = {
		"type": "tower",
		"tower_name": tower_name
	}
	# var preview = TextureRect.new()
	# preview.texture = tower_icon
	# preview.size = Vector2(64, 64) # Set a reasonable size for the preview
	# set_drag_preview(preview)
	return drag_data
