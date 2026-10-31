class_name StageExit
extends Area2D

## Stage exit gate that transitions to the next stage in Kampung Akal.

@export var target_stage_index: int = 2
@export var gate_title_bm: String = "Gerbang Peringkat Seterusnya"
@export var gate_title_en: String = "Next Stage Gate"
@export var locked_until_boss_defeated: bool = false

var _player_inside: PlayerController = null
var _is_unlocked: bool = true

@onready var arch_poly: Polygon2D = $ArchPoly
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GlobalSignalBus.language_changed.connect(_on_language_changed)
	GlobalSignalBus.boss_defeated.connect(_on_boss_defeated)
	_is_unlocked = not locked_until_boss_defeated
	_refresh_label()

func _process(_delta: float) -> void:
	if _player_inside != null and _is_unlocked and Input.is_action_just_pressed(&"interact"):
		_enter_gate()

func _enter_gate() -> void:
	GlobalSignalBus.interact_prompt_changed.emit(false, "")
	if target_stage_index <= GameStateManager.STAGE_PATHS.size():
		GameStateManager.start_stage(target_stage_index)
	else:
		get_tree().change_scene_to_file("res://features/ui/main_menu.tscn")

func _on_boss_defeated() -> void:
	_is_unlocked = true
	_refresh_label()

func _on_language_changed(_lang: StringName) -> void:
	_refresh_label()

func _refresh_label() -> void:
	if label == null:
		return
	var base := GameStateManager.t(gate_title_bm, gate_title_en)
	if not _is_unlocked:
		label.text = base + GameStateManager.t(" [Terkunci]", " [Locked]")
		arch_poly.color = Color(0.32, 0.22, 0.28, 1.0)
	else:
		label.text = base + GameStateManager.t(" [Tekan E]", " [Press E]")
		arch_poly.color = Color(0.92, 0.72, 0.24, 1.0)

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		_player_inside = body as PlayerController
		if _is_unlocked:
			var prompt := GameStateManager.t("Tekan [E] Masuk: ", "Press [E] Enter: ") + GameStateManager.t(gate_title_bm, gate_title_en)
			GlobalSignalBus.interact_prompt_changed.emit(true, prompt)

func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside = null
		GlobalSignalBus.interact_prompt_changed.emit(false, "")
