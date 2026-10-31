extends Node

## Global Signal Bus for decoupled communication across scenes and UI (< 15 lifecycle events).

signal health_changed(current_hp: int, max_hp: int)
signal ability_charges_changed(current_charges: int, max_charges: int)
signal combo_hit_landed(hit_index: int)
signal perfect_dodge_triggered()
signal player_died()
signal checkpoint_reached(shrine_name: String, respawn_position: Vector2)
signal lore_collected(lore_id: StringName, title: String, stage_collected: int, stage_total: int)
signal interact_prompt_changed(visible: bool, prompt_text: String)
signal boss_health_changed(boss_name: String, current_hp: int, max_hp: int, visible: bool)
signal boss_defeated()
signal stage_completed(next_scene_path: String)
signal language_changed(lang_code: StringName)
signal assist_options_changed()
