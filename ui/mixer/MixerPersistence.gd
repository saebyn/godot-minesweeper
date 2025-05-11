# Based on https://github.com/godotengine/godot-demo-projects/blob/4.2-31d1c0c/gui/input_mapping/KeyPersistence.gd
# License: MIT
# This file is based on part of the Godot demo projects.

# This is an autoload (singleton) which will save
# the key maps in a simple way through a dictionary.
extends Node

const audio_levels_path = "user://audio_levels.dat"
var audio_levels: Dictionary


func _ready() -> void:
  audio_levels = {
    "master": 100,
    "music": 100,
    "effects": 100,
  }
  load_audio_levels()
  push_bus_level("Master")
  push_bus_level("Music")
  push_bus_level("Effects")


func set_bus_level(bus_name: String, level: float) -> void:
  audio_levels[bus_name.to_lower()] = level
  save_audio_levels()
  push_bus_level(bus_name)

func push_bus_level(bus_name: String) -> void:
  var bus_index: int = AudioServer.get_bus_index(bus_name)
  var level = audio_levels[bus_name.to_lower()]
  AudioServer.set_bus_volume_linear(bus_index, level / 100.0)


func load_audio_levels() -> void:
  if not FileAccess.file_exists(audio_levels_path):
    save_audio_levels() # There is no save file yet, so let's create one.
    return
  var file = FileAccess.open(audio_levels_path, FileAccess.READ)
  audio_levels = file.get_var(true) as Dictionary
  file.close()


func save_audio_levels() -> void:
  # For saving the audio_levels, we just save the entire dictionary as a var.
  var file := FileAccess.open(audio_levels_path, FileAccess.WRITE)
  file.store_var(audio_levels, true)
  file.close()