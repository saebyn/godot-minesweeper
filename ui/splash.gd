extends Control

func exit_splash():
  get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_timeout():
  exit_splash()

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    if event.is_pressed():
      exit_splash()
  elif event is InputEventKey:
    exit_splash()
