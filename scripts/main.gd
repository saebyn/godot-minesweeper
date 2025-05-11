extends Node2D

@onready var game_menu := $GameMenu
@onready var game_scene := $GameScene
@onready var music_player := $MusicAudioStreamPlayer

func _ready() -> void:
  GameManager.game_over.connect(_on_game_manager_game_over)


func _on_game_manager_game_over(player_won: bool) -> void:
  # Pause the game when game over occurs
  get_tree().paused = true
  # Load the game over screen
  game_menu.show()
  game_scene.hide()

func _input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_cancel"):
    # Check if the game is paused
    if is_game_paused():
      # If the game is paused, resume it
      resume_game()
    else:
      # If the game is not paused, pause it
      pause_game()


func is_game_paused() -> bool:
  # Check if the game is paused
  return get_tree().paused


func pause_game() -> void:
  game_menu.pause()

func resume_game() -> void:
  game_menu.unpause()


func _on_game_menu_exit_game() -> void:
  # Exit the game
  get_tree().quit()


func _on_game_menu_return_main_menu() -> void:
  # Return to the main menu
  get_tree().paused = true
  game_menu.show()
  game_scene.hide()


func _on_game_menu_start_game() -> void:
  # Start the game
  get_tree().paused = false
  # Hide the game menu
  game_menu.hide()
  
  # Start the game scene
  game_scene.show()

  # start the music
  music_player.play()

  GameManager.reset_game()


func _on_game_menu_restart_game() -> void:
  print("Restarting game")
  GameManager.restart_level()
  resume_game()
