extends PanelContainer

@onready var label: Label = $VBoxContainer/Label

signal return_to_main_menu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  print("GameOverPanel ready")
  self.visible = false
  GameManager.game_over.connect(on_game_over)


func on_game_over(player_won: bool) -> void:
  print("Game Over: Player won =", player_won)
  self.visible = true
  if player_won:
    label.text = "You Win!"
  else:
    label.text = "Game Over"


func _on_game_over_panel_restart_game() -> void:
  print("Restarting game from GameOverPanel")
  GameManager.reset_game()
  self.visible = false

func _on_game_over_panel_exit_game() -> void:
  print("Exiting game from GameOverPanel")
  return_to_main_menu.emit()
  self.visible = false