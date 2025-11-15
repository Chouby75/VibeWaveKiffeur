class_name HUD
extends CanvasLayer

@onready var money_label := %MoneyLabel as Label
@onready var score_label := %ScoreLabel as Label
@onready var wave_label := %WaveLabel as Label
@onready var next_wave_panel := %NextWave as Panel
@onready var countdown_label := %Countdown as Label
@onready var next_wave_timer := %Timer as Timer
@onready var tier_unlock_label := %TierUnlock as Label
@onready var tier_unlock_timer := %TierUnlockTimer as Timer


func _on_spawner_countdown_started(seconds: float) -> void:
	next_wave_panel.show()
	next_wave_timer.start(seconds)


func _on_spawner_wave_started(current_wave: int) -> void:
	wave_label.text = "Wave: %d" % current_wave


func _on_money_changed(money: int) -> void:
	money_label.text = str(money)


func _on_score_changed(score: int) -> void:
	score_label.text = str(score)


func _on_tier_unlocked(tier_name: String) -> void:
	tier_unlock_label.text = "%s UNLOCKED" % tier_name
	tier_unlock_label.show()
	tier_unlock_timer.start()


func _on_tier_unlock_timer_timeout() -> void:
	tier_unlock_label.hide()


func _process(_delta: float) -> void:
	if not next_wave_timer.is_stopped():
		countdown_label.text = str(ceil(next_wave_timer.time_left))


func _on_timer_timeout():
	next_wave_panel.hide()
