extends Control

@onready var master_volume_slider: Slider = $"PanelContainer/VBoxContainer/GridContainer/MasterVolumeSlider"
@onready var music_volume_slider: Slider = $"PanelContainer/VBoxContainer/GridContainer/MusicVolumeSlider"
@onready var effects_volume_slider: Slider = $"PanelContainer/VBoxContainer/GridContainer/EffectsVolumeSlider"

func _ready() -> void:
  # Load the audio levels from the persistence singleton
  var master_volume: float = MixerPersistence.audio_levels.master
  var music_volume: float = MixerPersistence.audio_levels.music
  var effects_volume: float = MixerPersistence.audio_levels.effects


  # Set the sliders to the loaded values
  master_volume_slider.value = master_volume
  music_volume_slider.value = music_volume
  effects_volume_slider.value = effects_volume


func _on_done_button_pressed() -> void:
  queue_free()


func _on_master_volume_slider_value_changed(value: float) -> void:
  MixerPersistence.set_bus_level("Master", value)

func _on_music_volume_slider_value_changed(value: float) -> void:
  MixerPersistence.set_bus_level("Music", value)

func _on_effects_volume_slider_value_changed(value: float) -> void:
  MixerPersistence.set_bus_level("Effects", value)
