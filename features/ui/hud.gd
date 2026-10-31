class_name GameHUD
extends CanvasLayer

## Event-driven HUD + Lore Toast + Lore Library Modal + Pause/Assist Menu.
## Never modifies gameplay data directly; listens to GlobalSignalBus and toggles GameStateManager flags.

@export var stage_number: int = 1
@export var stage_title_bm: String = "Peringkat 1: Tepi Sungai Akal"
@export var stage_title_en: String = "Stage 1: Riverbank of Wit"

@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var trap_label: Label = %TrapLabel
@onready var lore_label: Label = %LoreLabel
@onready var stage_label: Label = %StageLabel
@onready var prompt_label: Label = %PromptLabel
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_title: Label = %ToastTitle
@onready var toast_body: Label = %ToastBody
@onready var boss_box: VBoxContainer = %BossBox
@onready var boss_name_label: Label = %BossNameLabel
@onready var boss_hp_bar: ProgressBar = %BossHPBar
@onready var pause_panel: PanelContainer = %PausePanel
@onready var lore_modal: PanelContainer = %LoreModal
@onready var lore_list_box: VBoxContainer = %LoreListBox
@onready var victory_panel: PanelContainer = %VictoryPanel

@onready var chk_slower: CheckBox = %ChkSlowerEnemies
@onready var chk_dodge: CheckBox = %ChkExtendedDodge
@onready var chk_double_jump: CheckBox = %ChkDoubleJump
@onready var chk_challenger: CheckBox = %ChkChallenger

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toast_panel.visible = false
	boss_box.visible = false
	pause_panel.visible = false
	lore_modal.visible = false
	victory_panel.visible = false
	prompt_label.visible = false

	GlobalSignalBus.health_changed.connect(_on_health_changed)
	GlobalSignalBus.ability_charges_changed.connect(_on_ability_charges_changed)
	GlobalSignalBus.lore_collected.connect(_on_lore_collected)
	GlobalSignalBus.interact_prompt_changed.connect(_on_interact_prompt_changed)
	GlobalSignalBus.boss_health_changed.connect(_on_boss_health_changed)
	GlobalSignalBus.boss_defeated.connect(_on_boss_defeated)
	GlobalSignalBus.language_changed.connect(_on_language_changed)

	(%BtnResume as Button).pressed.connect(_toggle_pause)
	(%BtnOpenLore as Button).pressed.connect(_open_lore_modal)
	(%BtnCloseLore as Button).pressed.connect(func() -> void: lore_modal.visible = false)
	(%BtnToggleLang as Button).pressed.connect(func() -> void: GameStateManager.toggle_language())
	(%BtnMainMenu as Button).pressed.connect(_return_to_main_menu)
	(%BtnVictoryMenu as Button).pressed.connect(_return_to_main_menu)

	chk_slower.button_pressed = GameStateManager.assist_slower_enemies
	chk_dodge.button_pressed = GameStateManager.assist_extended_dodge
	chk_double_jump.button_pressed = GameStateManager.assist_double_jump
	chk_challenger.button_pressed = GameStateManager.challenger_mode

	chk_slower.toggled.connect(func(v: bool) -> void:
		GameStateManager.assist_slower_enemies = v
		SaveManager.save_game()
	)
	chk_dodge.toggled.connect(func(v: bool) -> void:
		GameStateManager.assist_extended_dodge = v
		SaveManager.save_game()
	)
	chk_double_jump.toggled.connect(func(v: bool) -> void:
		GameStateManager.assist_double_jump = v
		SaveManager.save_game()
	)
	chk_challenger.toggled.connect(func(v: bool) -> void:
		GameStateManager.challenger_mode = v
		SaveManager.save_game()
	)

	_refresh_static_texts()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if lore_modal.visible:
			lore_modal.visible = false
		else:
			_toggle_pause()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused

func _return_to_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://features/ui/main_menu.tscn")

func _refresh_static_texts() -> void:
	stage_label.text = GameStateManager.t(stage_title_bm, stage_title_en)
	var collected := GameStateManager.get_stage_lore_collected_count(stage_number)
	var total := GameStateManager.get_stage_lore_total_count(stage_number)
	if total > 0:
		lore_label.text = "📜 %s: %d / %d" % [GameStateManager.t("Hikayat", "Lore"), collected, total]
	else:
		lore_label.text = "📜 %s: %d / 15" % [GameStateManager.t("Jumlah Hikayat", "Total Lore"), GameStateManager.get_total_lore_unlocked()]

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func _on_ability_charges_changed(current_charges: int, max_charges: int) -> void:
	trap_label.text = "🌿 %s [K]: %d / %d" % [GameStateManager.t("Umpan Kancil", "Bait Traps"), current_charges, max_charges]

func _on_lore_collected(lore_id: StringName, title: String, stage_collected: int, stage_total: int) -> void:
	lore_label.text = "📜 %s: %d / %d" % [GameStateManager.t("Hikayat", "Lore"), stage_collected, stage_total]
	toast_title.text = "📜 " + title
	toast_body.text = GameStateManager.get_lore_body(lore_id)
	toast_panel.visible = true
	var tw := create_tween()
	tw.tween_interval(4.5)
	tw.tween_callback(func() -> void: toast_panel.visible = false)

func _on_interact_prompt_changed(vis: bool, text: String) -> void:
	prompt_label.visible = vis
	prompt_label.text = text

func _on_boss_health_changed(boss_name: String, current_hp: int, max_hp: int, vis: bool) -> void:
	boss_box.visible = vis
	boss_name_label.text = boss_name
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = current_hp

func _on_boss_defeated() -> void:
	victory_panel.visible = true

func _on_language_changed(_lang: StringName) -> void:
	_refresh_static_texts()
	if lore_modal.visible:
		_populate_lore_modal()

func _open_lore_modal() -> void:
	_populate_lore_modal()
	lore_modal.visible = true

func _populate_lore_modal() -> void:
	for child: Node in lore_list_box.get_children():
		child.queue_free()

	for lore_id: StringName in GameStateManager.lore_catalog.keys():
		var unlocked := GameStateManager.is_lore_unlocked(lore_id)
		var item := Label.new()
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if unlocked:
			item.text = "✓ [%s] %s\n   %s" % [String(lore_id), GameStateManager.get_lore_title(lore_id), GameStateManager.get_lore_body(lore_id)]
			item.add_theme_color_override("font_color", Color(0.95, 0.92, 0.72, 1.0))
		else:
			item.text = "🔒 [%s] %s" % [String(lore_id), GameStateManager.t("Belum Ditemui — Terokai Kampung Akal", "Locked — Explore Kampung Akal")]
			item.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62, 1.0))
		lore_list_box.add_child(item)
