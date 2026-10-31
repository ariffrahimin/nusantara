extends Control

## Main Menu for Nusantara Chronicles MVP1:
## - Hero selection banner (Sang Kancil unlocked for MVP1; Hang Tuah & Puteri Gunung Ledang shown as Alpha/Beta preview)
## - Stage select for Kampung Akal (Stages 1, 2, 3, and Stage 4 Boss)
## - Bilingual Lore Library viewer (15 entries)
## - Language Toggle (Bahasa Melayu / English) & Save Slot selector (Slots 1-3)

@onready var subtitle_label: Label = %SubtitleLabel
@onready var hero_info_label: Label = %HeroInfoLabel
@onready var lore_summary_label: Label = %LoreSummaryLabel
@onready var btn_stage_1: Button = %BtnStage1
@onready var btn_stage_2: Button = %BtnStage2
@onready var btn_stage_3: Button = %BtnStage3
@onready var btn_stage_4: Button = %BtnStage4
@onready var btn_lore: Button = %BtnLoreLibrary
@onready var btn_lang: Button = %BtnLanguage
@onready var btn_slot: Button = %BtnSaveSlot
@onready var btn_quit: Button = %BtnQuit
@onready var lore_modal: PanelContainer = %LoreModal
@onready var lore_list_box: VBoxContainer = %LoreListBox
@onready var btn_close_lore: Button = %BtnCloseLore

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	lore_modal.visible = false

	btn_stage_1.pressed.connect(func() -> void: GameStateManager.start_stage(1))
	btn_stage_2.pressed.connect(func() -> void: GameStateManager.start_stage(2))
	btn_stage_3.pressed.connect(func() -> void: GameStateManager.start_stage(3))
	btn_stage_4.pressed.connect(func() -> void: GameStateManager.start_stage(4))
	btn_lore.pressed.connect(_open_lore_library)
	btn_close_lore.pressed.connect(func() -> void: lore_modal.visible = false)
	btn_lang.pressed.connect(func() -> void: GameStateManager.toggle_language())
	btn_slot.pressed.connect(_cycle_save_slot)
	btn_quit.pressed.connect(func() -> void: get_tree().quit())

	GlobalSignalBus.language_changed.connect(_on_language_changed)
	_refresh_ui()
	btn_stage_1.grab_focus()

func _cycle_save_slot() -> void:
	var next_slot := (SaveManager.active_slot % 3) + 1
	SaveManager.load_game(next_slot)
	_refresh_ui()

func _on_language_changed(_lang: StringName) -> void:
	_refresh_ui()
	if lore_modal.visible:
		_populate_lore_list()

func _refresh_ui() -> void:
	subtitle_label.text = GameStateManager.t(
		"Pengembaraan Aksi-Platformer Hikayat Alam Nusantara — MVP1: Kampung Akal",
		"A Malay Folklore Platformer-Action Adventure — MVP1: Kampung Akal"
	)
	hero_info_label.text = GameStateManager.t(
		"🦌 WIRA MVP1: SANG KANCIL (Sang Pintar / Pengakap)\n• Kebolehan Khas [K / Klik Kanan]: Pasang Umpan Keranji untuk memperdaya musuh & memukau Bos\n• Sifat Pasif: Tempoh Elak Sempurna [Left Shift / L] 50% lebih luas dengan gerak perlahan",
		"🦌 MVP1 HERO: SANG KANCIL (Trickster / Scout)\n• Special Ability [K / Right Click]: Deploy Bait Trap to distract enemies & stun the Boss\n• Passive Trait: Perfect Dodge [Left Shift / L] window is 50% larger with slow-motion"
	)
	var s1 := GameStateManager.get_stage_lore_collected_count(1)
	var s2 := GameStateManager.get_stage_lore_collected_count(2)
	var s3 := GameStateManager.get_stage_lore_collected_count(3)
	var total := GameStateManager.get_total_lore_unlocked()

	lore_summary_label.text = GameStateManager.t(
		"📜 Kemajuan Hikayat Kampung Akal: %d / 15 Ditemui (P1: %d/5 | P2: %d/5 | P3: %d/5)" % [total, s1, s2, s3],
		"📜 Kampung Akal Lore Progress: %d / 15 Discovered (S1: %d/5 | S2: %d/5 | S3: %d/5)" % [total, s1, s2, s3]
	)

	btn_stage_1.text = GameStateManager.t(
		"▶ Peringkat 1: Tepi Sungai Akal (Tutorial & 5 Hikayat)",
		"▶ Stage 1: Riverbank of Wit (Tutorial & 5 Lore)"
	)
	btn_stage_2.text = GameStateManager.t(
		"▶ Peringkat 2: Dusun Terlarang (Kombo, Platform & 5 Hikayat)",
		"▶ Stage 2: Forbidden Orchard (Combos, Platforms & 5 Lore)"
	)
	btn_stage_3.text = GameStateManager.t(
		"▶ Peringkat 3: Sarang Kegelapan (Taktik Umpan & 5 Hikayat)",
		"▶ Stage 3: Heart of Corruption (Bait Trap Tactics & 5 Lore)"
	)
	btn_stage_4.text = GameStateManager.t(
		"⚔️ Peringkat 4 (BOS): Lubuk Sang Buaya Hitam",
		"⚔️ Stage 4 (BOSS): Lair of Sang Buaya Hitam"
	)
	btn_lore.text = GameStateManager.t("📜 Buka Pustaka Hikayat (%d/15)" % total, "📜 Open Lore Library (%d/15)" % total)
	btn_lang.text = GameStateManager.t("🌐 Bahasa: BAHASA MELAYU (Tukar ke English)", "🌐 Language: ENGLISH (Switch to Bahasa Melayu)")
	btn_slot.text = GameStateManager.t("💾 Slot Simpanan Aktif: Slot %d / 3 (Klik untuk Tukar)" % SaveManager.active_slot, "💾 Active Save Slot: Slot %d / 3 (Click to Switch)" % SaveManager.active_slot)
	btn_quit.text = GameStateManager.t("Keluar Permainan", "Quit Game")

func _open_lore_library() -> void:
	_populate_lore_list()
	lore_modal.visible = true

func _populate_lore_list() -> void:
	for child: Node in lore_list_box.get_children():
		child.queue_free()
	for lore_id: StringName in GameStateManager.lore_catalog.keys():
		var unlocked := GameStateManager.is_lore_unlocked(lore_id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if unlocked:
			lbl.text = "✓ [%s] %s\n   %s" % [String(lore_id), GameStateManager.get_lore_title(lore_id), GameStateManager.get_lore_body(lore_id)]
			lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.68, 1.0))
		else:
			lbl.text = "🔒 [%s] %s" % [String(lore_id), GameStateManager.t("Belum Ditemui — Cari di Kampung Akal", "Locked — Discover in Kampung Akal")]
			lbl.add_theme_color_override("font_color", Color(0.55, 0.56, 0.62, 1.0))
		lore_list_box.add_child(lbl)
