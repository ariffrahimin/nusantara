class_name HeroData
extends Resource

@export var hero_id: StringName = &"sang_kancil"
@export var display_name: String = "Sang Kancil"
@export var archetype_bm: String = "Sang Pintar / Pengakap"
@export var archetype_en: String = "Trickster / Scout"
@export var max_hp: int = 100
@export var move_speed: float = 310.0
@export var jump_height: float = 118.0
@export var time_to_apex: float = 0.34
@export var fall_gravity_multiplier: float = 1.75
@export var base_dodge_window: float = 0.16
@export var dodge_window_multiplier: float = 1.5 # Sang Kancil passive: +50% dodge window
@export var max_ability_charges: int = 3
@export var combo_damage: PackedInt32Array = PackedInt32Array([12, 16, 26])
