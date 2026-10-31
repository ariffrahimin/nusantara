extends SceneTree

## Headless verification suite for Nusantara Chronicles MVP1.
## Runs after Main::start() registers Autoload singletons so all scripts resolve Autoload identifiers cleanly.

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	await run_all_tests()
	print("MVP1 Test Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected [%s], got [%s]" % [label, str(expected), str(actual)])

func assert_true(cond: bool, label: String) -> void:
	assert_eq(cond, true, label)

func run_all_tests() -> void:
	await process_frame

	# 1. Verify 15 Lore Entries in GameStateManager (5 per stage for Stages 1..3)
	var gsm: Node = root.get_node_or_null("GameStateManager")
	assert_true(gsm != null, "autoload_GameStateManager_exists")
	assert_eq(gsm.call("get_stage_lore_total_count", 1), 5, "stage_1_has_5_lore_entries")
	assert_eq(gsm.call("get_stage_lore_total_count", 2), 5, "stage_2_has_5_lore_entries")
	assert_eq(gsm.call("get_stage_lore_total_count", 3), 5, "stage_3_has_5_lore_entries")

	# 2. Verify Main Menu & all 4 Kampung Akal stages instantiate cleanly
	var scenes_to_check: Array[String] = [
		"res://features/ui/main_menu.tscn",
		"res://stages/kampung_akal/stage_01_tepi_sungai.tscn",
		"res://stages/kampung_akal/stage_02_dusun_terlarang.tscn",
		"res://stages/kampung_akal/stage_03_sarang_kegelapan.tscn",
		"res://stages/kampung_akal/stage_04_boss_buaya.tscn",
	]
	for path: String in scenes_to_check:
		var packed := load(path) as PackedScene
		assert_true(packed != null, "load_" + path)
		if packed != null:
			var inst := packed.instantiate()
			root.add_child(inst)
			await process_frame
			assert_true(inst.is_inside_tree(), "instance_in_tree_" + path)
			inst.queue_free()
			await process_frame

	# 3. Verify Sang Kancil Bait Trap & Penunggu Shrine replenishment in Stage 1
	var stage1_packed := load("res://stages/kampung_akal/stage_01_tepi_sungai.tscn") as PackedScene
	var stage1 := stage1_packed.instantiate()
	root.add_child(stage1)
	await process_frame

	var player: Node = stage1.get_node_or_null("Player")
	assert_true(player != null, "stage1_has_player")
	assert_eq(player.get("ability_charges"), 3, "kancil_starts_with_3_bait_traps")
	var deployed: bool = bool(player.call("deploy_bait_trap"))
	assert_true(deployed, "kancil_deployed_bait_trap")
	assert_eq(player.get("ability_charges"), 2, "kancil_charges_decremented_to_2")

	var shrine: Node = stage1.get_node_or_null("Shrines/ShrineRiverbank")
	assert_true(shrine != null, "stage1_has_shrine")
	shrine.call("activate_shrine", player)
	assert_eq(player.get("ability_charges"), 3, "shrine_replenished_bait_traps_to_3")

	var lore1: Node = stage1.get_node_or_null("LoreFragments/Lore1")
	assert_true(lore1 != null, "stage1_has_lore1")
	lore1.call("collect")
	assert_true(bool(gsm.call("is_lore_unlocked", &"ka_s1_01")), "lore_ka_s1_01_unlocked")

	stage1.queue_free()
	await process_frame

	# 4. Verify Stage 4 Boss (Sang Buaya Hitam) Bait Trap Stun & Victory Gate unlock
	var stage4_packed := load("res://stages/kampung_akal/stage_04_boss_buaya.tscn") as PackedScene
	var stage4 := stage4_packed.instantiate()
	root.add_child(stage4)
	await process_frame

	var boss: Node = stage4.get_node_or_null("BossBuaya")
	var exit_gate: Node = stage4.get_node_or_null("VictoryExit")
	assert_true(boss != null, "stage4_has_boss_buaya")
	assert_true(exit_gate != null, "stage4_has_victory_exit")
	assert_eq(exit_gate.get("_is_unlocked"), false, "victory_exit_starts_locked")

	boss.call("on_hit_bait_trap", 20)
	assert_eq(boss.get("_state"), 3, "boss_stunned_by_bait_trap")
	boss.call("take_damage", 400)
	assert_eq(boss.get("_state"), 5, "boss_defeated_at_0_hp")
	assert_eq(exit_gate.get("_is_unlocked"), true, "victory_exit_unlocked_after_boss_defeat")

	stage4.queue_free()
	await process_frame
	root.get_node("SaveManager").call("reset_save", 1)
