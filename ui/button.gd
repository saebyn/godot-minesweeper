extends Button

var tween: Tween
var original_scale: Vector2
@export var tween_duration: float = 0.2
@export var tween_scale: float = 1.1

func _ready() -> void:
  original_scale = scale
  # Connect the mouse enter and exit signals
  self.connect("mouse_entered", _on_mouse_enter)
  self.connect("mouse_exited", _on_mouse_exit)
  # Connect the resize signal
  self.connect("resized", _on_resize)


func _on_resize() -> void:
  # Set the pivot point to the center of the button
  pivot_offset = size / 2

func _on_mouse_enter() -> void:
  if tween:
    tween.kill()
    tween = null

  tween = create_tween()
  tween.set_pause_mode(Tween.TweenPauseMode.TWEEN_PAUSE_PROCESS)
  tween.tween_property(self, "scale", Vector2(tween_scale, tween_scale), tween_duration)


func _on_mouse_exit() -> void:
  if tween:
    tween.kill()
    tween = null

  tween = create_tween()
  tween.set_pause_mode(Tween.TweenPauseMode.TWEEN_PAUSE_PROCESS)
  tween.tween_property(self, "scale", original_scale, tween_duration)
