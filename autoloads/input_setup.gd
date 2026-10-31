extends Node

## Ensures all Nusantara Chronicles input actions are bound at startup (A/D/Arrows, Space/W, J/LMB, K/RMB, Shift/L, E, Esc).

func _ready() -> void:
	_setup_inputs()

func _setup_inputs() -> void:
	_bind_keys(&"move_left", [KEY_A, KEY_LEFT])
	_bind_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_keys(&"move_down", [KEY_S, KEY_DOWN])
	_bind_keys(&"jump", [KEY_SPACE, KEY_W, KEY_UP])
	_bind_keys(&"attack", [KEY_J], [MOUSE_BUTTON_LEFT])
	_bind_keys(&"special_ability", [KEY_K], [MOUSE_BUTTON_RIGHT])
	_bind_keys(&"dodge", [KEY_SHIFT, KEY_L])
	_bind_keys(&"interact", [KEY_E])
	_bind_keys(&"pause", [KEY_ESCAPE, KEY_P])

func _bind_keys(action: StringName, keys: Array[Key], mouse_buttons: Array[MouseButton] = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	else:
		InputMap.action_erase_events(action)

	for k: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

	for mb: MouseButton in mouse_buttons:
		var mev := InputEventMouseButton.new()
		mev.button_index = mb
		InputMap.action_add_event(action, mev)
