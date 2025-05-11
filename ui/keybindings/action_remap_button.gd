extends Button


@export var action: String = "ui_up"

func _ready() -> void:
  assert(InputMap.has_action(action), "Action not found in InputMap: " + action)
  set_process_unhandled_key_input(false)
  display_current_keybind()


func _toggled(toggled_on: bool) -> void:
  set_process_unhandled_key_input(true)
  if toggled_on:
    text = "<press a key>"
    release_focus()
  else:
    display_current_keybind()


func _unhandled_key_input(event: InputEvent) -> void:
  InputMap.action_erase_events(action)
  InputMap.action_add_event(action, event)
  KeyPersistence.keymaps[action] = event
  KeyPersistence.save_keymap()
  text = event.as_text()
  button_pressed = false
  set_process_unhandled_key_input(false)


func display_current_keybind() -> void:
  var current_key := InputMap.action_get_events(action)[0].as_text()
  text = current_key
