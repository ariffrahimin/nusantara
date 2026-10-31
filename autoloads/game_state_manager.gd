extends Node

## Manages game state, bilingual lore database (15 Kampung Akal entries), assist options, and stage progress.

const STAGE_PATHS: Array[String] = [
	"res://stages/kampung_akal/stage_01_tepi_sungai.tscn",
	"res://stages/kampung_akal/stage_02_dusun_terlarang.tscn",
	"res://stages/kampung_akal/stage_03_sarang_kegelapan.tscn",
	"res://stages/kampung_akal/stage_04_boss_buaya.tscn",
]

var language: StringName = &"BM" # &"BM" (Bahasa Melayu) or &"EN" (English)
var current_stage_index: int = 1
var unlocked_lore_ids: Dictionary = {} # StringName -> bool
var highest_unlocked_stage: int = 1

# Checkpoint state within the active stage
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_shrine_name: String = ""

# Assist options (GDD Section 4.5)
var assist_slower_enemies: bool = false
var assist_extended_dodge: bool = false
var assist_double_jump: bool = false
var challenger_mode: bool = false

# 15 Bilingual Lore Entries for Kampung Akal (5 per stage across 3 exploration stages)
var lore_catalog: Dictionary = {
	# Stage 1: Tepi Sungai Akal (Riverbank of Wit)
	&"ka_s1_01": {
		"stage": 1,
		"title_bm": "Sang Kancil & Barisan Buaya",
		"title_en": "Sang Kancil & The Crocodile Bridge",
		"body_bm": "Dalam kisah rakyat Melayu klasik, Sang Kancil memperdaya sekawan buaya supaya berbaris merentasi sungai dengan alasan mahu membilang jumlah mereka untuk jamuan Raja Sulaiman.",
		"body_en": "In classic Malay folklore, the mouse-deer Sang Kancil tricked a river of crocodiles into lining up from bank to bank by claiming King Solomon had ordered a royal feast census."
	},
	&"ka_s1_02": {
		"stage": 1,
		"title_bm": "Akal Mengalahkan Kekuatan",
		"title_en": "Wit Over Brute Force",
		"body_bm": "Pelanduk atau kancil ialah haiwan kecil di hutan hujan Nusantara, namun dalam sastera lisan Melayu ia menjadi lambang kebijaksanaan rakyat biasa menghadapi penguasa yang zalim.",
		"body_en": "Though tiny among rainforest beasts, the mouse-deer symbolizes sharp intellect in Nusantara oral tradition—proving cleverness triumphs over sheer size."
	},
	&"ka_s1_03": {
		"stage": 1,
		"title_bm": "Penunggu Tepian Air",
		"title_en": "Guardians of the Water's Edge",
		"body_bm": "Masyarakat Melayu dahulu percaya setiap lubuk sungai dan pokok beringin tua dijaga oleh Penunggu. Memberi salam dan menghormati alam memastikan perjalanan selamat.",
		"body_en": "Traditional Malay communities believed ancient river bends and banyan trees housed Penunggu spirits. Honouring nature ensured safe passage."
	},
	&"ka_s1_04": {
		"stage": 1,
		"title_bm": "Sumpahan Kegelapan",
		"title_en": "The Ink of Kegelapan",
		"body_bm": "Kegelapan lahir daripada janji yang dimungkiri antara manusia dan Alam Ghaib. Ia menumpahkan dakwat hitam ke atas corak batik alam dan memadamkan ingatan cerita lama.",
		"body_en": "Kegelapan emerged from a broken oath between humankind and the unseen spirit world, spilling black ink over vibrant batik patterns and erasing cultural memory."
	},
	&"ka_s1_05": {
		"stage": 1,
		"title_bm": "Jerat Buah Keranji",
		"title_en": "The Keranji Fruit Snare",
		"body_bm": "Sang Kancil sering menggunakan buah-buahan hutan yang harum sebagai umpan untuk mengalihkan perhatian pemangsa sebelum meloloskan diri tanpa pertumpahan darah.",
		"body_en": "Sang Kancil often used fragrant jungle fruits as bait to distract fierce predators, slipping past danger through misdirection."
	},

	# Stage 2: Dusun Terlarang (Forbidden Orchard)
	&"ka_s2_01": {
		"stage": 2,
		"title_bm": "Gong DiRaja (Sarang Tebuan)",
		"title_en": "The Royal Gong (Hornet's Nest)",
		"body_bm": "Apabila Sang Harimau hendak memakannya, Sang Kancil menunjuk ke arah sarang tebuan dan mendakwa ia 'Gong Nabi Sulaiman' yang hanya boleh dipukul selepas beliau pergi jauh.",
		"body_en": "Cornered by a tiger, Sang Kancil pointed to a giant hornet's nest and claimed it was King Solomon's sacred gong—convincing the tiger to strike it once Kancil was safely away."
	},
	&"ka_s2_02": {
		"stage": 2,
		"title_bm": "Tali Pinggang Sakti (Ular Sawa)",
		"title_en": "The Magic Sash (The Python)",
		"body_bm": "Sang Kancil pernah memperdaya harimau yang angkuh agar memakai 'bengkung diraja' yang sebenarnya seekor ular sawa sedang tidur di dahan pohon.",
		"body_en": "Sang Kancil once convinced a boastful predator to wear a 'royal waist sash'—which turned out to be a coiled python resting in the branches."
	},
	&"ka_s2_03": {
		"stage": 2,
		"title_bm": "Seni Ukiran Kayu Melayu",
		"title_en": "Malay Woodcarving Motifs",
		"body_bm": "Ukiran 'Awan Larat' pada rumah kampung melambangkan keharmonian hidup yang saling berkaitan dan tidak terputus, menjadi pelindung rohani daripada ancaman gelap.",
		"body_en": "The flowing 'Awan Larat' (meandering cloud) woodcarvings on traditional kampung houses symbolize unbroken harmony with nature."
	},
	&"ka_s2_04": {
		"stage": 2,
		"title_bm": "Lompatan Bayang Wayang Kulit",
		"title_en": "Shadow Puppet Silhouette",
		"body_bm": "Dalam persembahan Wayang Kulit Kelantan, Tok Dalang menghidupkan watak-watak hikayat di sebalik kelir putih menggunakan cahaya lampu dan irama gamelan.",
		"body_en": "In Kelantanese Wayang Kulit shadow theatre, the master puppeteer (Tok Dalang) brings mythical heroes to life behind a backlit screen."
	},
	&"ka_s2_05": {
		"stage": 2,
		"title_bm": "Perangkap Lubang & Kayu Уkur",
		"title_en": "The Pit Trap Escape",
		"body_bm": "Ketika terjatuh ke dalam lubang perangkap pemburu, Sang Kancil berpura-pura membaca mantera langit runtuh sehingga haiwan lain melompat masuk dan menjadi tangga keluarnya.",
		"body_en": "Trapped in a hunter's pit, Sang Kancil pretended the sky was falling and recited a 'protective' chant, luring larger beasts inside so he could leap out off their backs."
	},

	# Stage 3: Sarang Kegelapan (Heart of Corruption)
	&"ka_s3_01": {
		"stage": 3,
		"title_bm": "Hakim Rimba Raya",
		"title_en": "Judge of the Great Jungle",
		"body_bm": "Keupayaan Sang Kancil menyelesaikan pertikaian antara peniaga, petani, dan buaya menjadikannya digelar 'Syeikh Alam di Rimba' dalam hikayat lama.",
		"body_en": "Sang Kancil's legendary fairness in settling disputes between merchants, farmers, and beasts earned him the title 'Sage of the Forest' in classical manuscripts."
	},
	&"ka_s3_02": {
		"stage": 3,
		"title_bm": "Gergasi & Tulang Belakang",
		"title_en": "Outsmarting the Forest Giant",
		"body_bm": "Berhadapan dengan Gergasi yang ganas, Sang Kancil menawarkan diri untuk mengubati sakit belakang Gergasi menggunakan rotan—lalu mengikatnya dengan pintar.",
		"body_en": "Confronted by a rampaging forest giant, Sang Kancil offered a traditional rattan 'back-straightening cure' that cleverly bound the giant's limbs."
	},
	&"ka_s3_03": {
		"stage": 3,
		"title_bm": "Kuasa Cerita Lisan",
		"title_en": "Power of the Spoken Story",
		"body_bm": "Di Alam Nusantara, Kegelapan tidak dapat menembusi tempat di mana kisah warisan masih diceritakan. Mengumpul fragmen hikayat memulihkan cahaya kampung.",
		"body_en": "In Alam Nusantara, Kegelapan cannot enter places where ancestral stories are actively remembered. Recovering lore fragments restores light to the land."
	},
	&"ka_s3_04": {
		"stage": 3,
		"title_bm": "Dendam Sang Buaya Hitam",
		"title_en": "Wrath of Sang Buaya Hitam",
		"body_bm": "Raja Buaya di muara Kampung Akal masih menyimpan dendam kerana pernah diperdaya menjadi jambatan. Kegelapan telah meresap ke dalam kemarahannya.",
		"body_en": "The Crocodile King of Kampung Akal still nurses a bitter grudge from being used as a stepping bridge. Kegelapan has twisted his resentment into monstrous rage."
	},
	&"ka_s3_05": {
		"stage": 3,
		"title_bm": "Ikatan Alam Ghaib",
		"title_en": "The Spirit World Covenant",
		"body_bm": "Apabila ketiga-tiga prasasti kampung disucikan, laluan ke lubuk Sang Buaya Hitam terbuka untuk membebaskan Kampung Akal daripada cengkaman Kegelapan.",
		"body_en": "When the village's ancestral scrolls are reclaimed, the path to Sang Buaya Hitam's lair opens so Kampung Akal can be freed from Kegelapan."
	}
}

func t(bm_text: String, en_text: String) -> String:
	return bm_text if language == &"BM" else en_text

func set_language(lang: StringName) -> void:
	language = lang
	GlobalSignalBus.language_changed.emit(language)
	SaveManager.save_game()

func toggle_language() -> void:
	set_language(&"EN" if language == &"BM" else &"BM")

func unlock_lore(lore_id: StringName) -> void:
	var entry: Dictionary = lore_catalog.get(lore_id, {})
	var stage_num: int = int(entry.get("stage", current_stage_index))
	unlocked_lore_ids[lore_id] = true
	var title: String = get_lore_title(lore_id)
	var collected_in_stage := get_stage_lore_collected_count(stage_num)
	var total_in_stage := get_stage_lore_total_count(stage_num)
	GlobalSignalBus.lore_collected.emit(lore_id, title, collected_in_stage, total_in_stage)
	SaveManager.save_game()

func is_lore_unlocked(lore_id: StringName) -> bool:
	return unlocked_lore_ids.get(lore_id, false)

func get_lore_title(lore_id: StringName) -> String:
	var entry: Dictionary = lore_catalog.get(lore_id, {})
	if entry.is_empty():
		return String(lore_id)
	return String(entry.get("title_bm", "")) if language == &"BM" else String(entry.get("title_en", ""))

func get_lore_body(lore_id: StringName) -> String:
	var entry: Dictionary = lore_catalog.get(lore_id, {})
	if entry.is_empty():
		return ""
	return String(entry.get("body_bm", "")) if language == &"BM" else String(entry.get("body_en", ""))

func get_stage_lore_collected_count(stage_num: int) -> int:
	var count := 0
	for lore_id: StringName in lore_catalog.keys():
		var entry: Dictionary = lore_catalog[lore_id]
		if int(entry.get("stage", 0)) == stage_num and unlocked_lore_ids.get(lore_id, false):
			count += 1
	return count

func get_stage_lore_total_count(stage_num: int) -> int:
	var count := 0
	for lore_id: StringName in lore_catalog.keys():
		var entry: Dictionary = lore_catalog[lore_id]
		if int(entry.get("stage", 0)) == stage_num:
			count += 1
	return count

func get_total_lore_unlocked() -> int:
	return unlocked_lore_ids.size()

func set_checkpoint(shrine_name: String, world_pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_shrine_name = shrine_name
	checkpoint_position = world_pos
	GlobalSignalBus.checkpoint_reached.emit(shrine_name, world_pos)
	SaveManager.save_game()

func clear_stage_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_shrine_name = ""
	checkpoint_position = Vector2.ZERO

func start_stage(stage_idx: int) -> void:
	current_stage_index = clampi(stage_idx, 1, STAGE_PATHS.size())
	if current_stage_index > highest_unlocked_stage:
		highest_unlocked_stage = current_stage_index
	clear_stage_checkpoint()
	SaveManager.save_game()
	get_tree().change_scene_to_file(STAGE_PATHS[current_stage_index - 1])

func advance_to_next_stage() -> void:
	var next_idx := current_stage_index + 1
	if next_idx <= STAGE_PATHS.size():
		start_stage(next_idx)
	else:
		get_tree().change_scene_to_file("res://features/ui/main_menu.tscn")
