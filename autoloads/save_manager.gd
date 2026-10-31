extends Node

## Handles local persistence for Nusantara Chronicles MVP1 (3 save slots supported, defaults to slot 1).

const SAVE_PATH_TEMPLATE := "user://nusantara_save_slot_%d.cfg"
var active_slot: int = 1

func _ready() -> void:
	load_game(active_slot)

func get_save_path(slot: int = active_slot) -> String:
	return SAVE_PATH_TEMPLATE % slot

func save_game(slot: int = active_slot) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "language", String(GameStateManager.language))
	cfg.set_value("meta", "current_stage_index", GameStateManager.current_stage_index)
	cfg.set_value("meta", "highest_unlocked_stage", GameStateManager.highest_unlocked_stage)
	cfg.set_value("assist", "slower_enemies", GameStateManager.assist_slower_enemies)
	cfg.set_value("assist", "extended_dodge", GameStateManager.assist_extended_dodge)
	cfg.set_value("assist", "double_jump", GameStateManager.assist_double_jump)
	cfg.set_value("assist", "challenger_mode", GameStateManager.challenger_mode)

	var unlocked_list: PackedStringArray = PackedStringArray()
	for lore_id: StringName in GameStateManager.unlocked_lore_ids.keys():
		if GameStateManager.unlocked_lore_ids[lore_id]:
			unlocked_list.append(String(lore_id))
	cfg.set_value("progression", "unlocked_lore", unlocked_list)

	cfg.save(get_save_path(slot))

func load_game(slot: int = active_slot) -> void:
	active_slot = slot
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return

	GameStateManager.language = StringName(cfg.get_value("meta", "language", "BM"))
	GameStateManager.current_stage_index = int(cfg.get_value("meta", "current_stage_index", 1))
	GameStateManager.highest_unlocked_stage = int(cfg.get_value("meta", "highest_unlocked_stage", 1))
	GameStateManager.assist_slower_enemies = bool(cfg.get_value("assist", "slower_enemies", false))
	GameStateManager.assist_extended_dodge = bool(cfg.get_value("assist", "extended_dodge", false))
	GameStateManager.assist_double_jump = bool(cfg.get_value("assist", "double_jump", false))
	GameStateManager.challenger_mode = bool(cfg.get_value("assist", "challenger_mode", false))

	GameStateManager.unlocked_lore_ids.clear()
	var unlocked_list: PackedStringArray = cfg.get_value("progression", "unlocked_lore", PackedStringArray())
	for item: String in unlocked_list:
		GameStateManager.unlocked_lore_ids[StringName(item)] = true

func reset_save(slot: int = active_slot) -> void:
	GameStateManager.unlocked_lore_ids.clear()
	GameStateManager.current_stage_index = 1
	GameStateManager.highest_unlocked_stage = 1
	GameStateManager.clear_stage_checkpoint()
	save_game(slot)
