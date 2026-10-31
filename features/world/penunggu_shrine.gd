class_name PenungguShrine
extends Area2D

## Sacred spirit guardian shrine:
## - Press E to honour the Penunggu
## - Sets active checkpoint, restores HP, refills Sang Kancil's Bait Trap charges, and saves progress.

@export var shrine_name_bm: String = "Keramat Penunggu Beringin"
@export var shrine_name_en: String = "Banyan Penunggu Shrine"

var _player_inside: PlayerController = null
var _is_honoured: bool = false

@onready var aura_poly: Polygon2D = $AuraPoly
@onready var pillar_poly: Polygon2D = $PillarPoly
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GlobalSignalBus.language_changed.connect(_on_language_changed)
	_refresh_visuals()

func _process(_delta: float) -> void:
	if _player_inside != null and Input.is_action_just_pressed(&"interact"):
		activate_shrine(_player_inside)

func activate_shrine(player: PlayerController) -> void:
	_is_honoured = true
	var display_title := GameStateManager.t(shrine_name_bm, shrine_name_en)
	GameStateManager.set_checkpoint(display_title, global_position + Vector2(0, -4))
	if player != null:
		player.set_checkpoint_pos(global_position + Vector2(0, -4))
		player.heal_and_replenish()
	_refresh_visuals()

func _refresh_visuals() -> void:
	if name_label:
		var title := GameStateManager.t(shrine_name_bm, shrine_name_en)
		var state_txt := GameStateManager.t(" [AKTIF]", " [ACTIVE]") if _is_honoured else GameStateManager.t(" [Tekan E]", " [Press E]")
		name_label.text = title + state_txt
	if aura_poly:
		aura_poly.color = Color(0.25, 0.95, 0.72, 0.36) if _is_honoured else Color(0.75, 0.65, 0.25, 0.16)
	if pillar_poly:
		pillar_poly.color = Color(0.28, 0.78, 0.62, 1.0) if _is_honoured else Color(0.42, 0.38, 0.32, 1.0)

func _on_language_changed(_lang: StringName) -> void:
	_refresh_visuals()

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		_player_inside = body as PlayerController
		var prompt := GameStateManager.t("Tekan [E] Hormati Penunggu (Pulih & Simpan)", "Press [E] Honour Penunggu (Heal & Save)")
		GlobalSignalBus.interact_prompt_changed.emit(true, prompt)
		# Auto-checkpoint on first touch per GDD 4.5 ("Auto-save at every major encounter; manual save at shrines")
		if not _is_honoured:
			activate_shrine(_player_inside)

func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside = null
		GlobalSignalBus.interact_prompt_changed.emit(false, "")
