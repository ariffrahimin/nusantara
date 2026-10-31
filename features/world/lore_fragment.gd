class_name LoreFragment
extends Area2D

## Collectible Malay folklore scroll:
## - Press E (or touch if auto_collect_on_interact is enabled) to unlock the lore entry in GameStateManager
## - Clears the local Kegelapan ink stain around the scroll ("Kegelapan cannot enter places where stories are actively being told").

@export var lore_id: StringName = &"ka_s1_01"

var _player_inside: PlayerController = null
var _collected: bool = false
var _bob_time: float = 0.0

@onready var scroll_visual: Node2D = $ScrollVisual
@onready var ink_veil: Polygon2D = $KegelapanInkVeil
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GlobalSignalBus.language_changed.connect(_on_language_changed)
	_collected = GameStateManager.is_lore_unlocked(lore_id)
	_update_visual_state()

func _process(delta: float) -> void:
	_bob_time += delta * 3.2
	if scroll_visual:
		scroll_visual.position.y = -32.0 + sin(_bob_time) * 5.0
	if _player_inside != null and not _collected and Input.is_action_just_pressed(&"interact"):
		collect()

func collect() -> void:
	if _collected:
		return
	_collected = true
	GameStateManager.unlock_lore(lore_id)
	_update_visual_state()
	GlobalSignalBus.interact_prompt_changed.emit(false, "")

func _update_visual_state() -> void:
	var title := GameStateManager.get_lore_title(lore_id)
	if _collected:
		if ink_veil:
			ink_veil.color = Color(0.25, 0.92, 0.68, 0.14)
		if scroll_visual:
			scroll_visual.modulate = Color(0.55, 1.0, 0.85, 0.45)
		if label:
			label.text = "✓ " + title
	else:
		if ink_veil:
			ink_veil.color = Color(0.08, 0.05, 0.12, 0.48)
		if scroll_visual:
			scroll_visual.modulate = Color(1, 1, 1, 1)
		if label:
			label.text = "📜 " + title + GameStateManager.t(" [E]", " [E]")

func _on_language_changed(_lang: StringName) -> void:
	_update_visual_state()

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		_player_inside = body as PlayerController
		if not _collected:
			var prompt := GameStateManager.t("Tekan [E] Kumpul Hikayat: ", "Press [E] Collect Lore: ") + GameStateManager.get_lore_title(lore_id)
			GlobalSignalBus.interact_prompt_changed.emit(true, prompt)

func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside = null
		GlobalSignalBus.interact_prompt_changed.emit(false, "")
