class_name PlayerController
extends CharacterBody2D

## Sang Kancil playable controller:
## - Platformer movement with Coyote Time, Jump Buffering, Variable Jump Height, One-Way Drop
## - 3-Hit Combo system (Attack x3)
## - Perfect Dodge with +50% Trickster window & brief slow-motion pulse
## - Bait Trap Special Ability (3 charges replenished at Penunggu Shrines)

const BAIT_TRAP_SCENE := preload("res://features/player/bait_trap.tscn")
const DEFAULT_HERO_DATA := preload("res://data/heroes/sang_kancil.tres")

@export var hero_data: HeroData = DEFAULT_HERO_DATA

# Derived jump physics
var _rise_gravity: float = 1950.0
var _fall_gravity: float = 3400.0
var _jump_velocity: float = -680.0
var _max_fall_speed: float = 980.0

# Platformer feel timers
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER_TIME: float = 0.12
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _air_jumps_left: int = 0

# Stats & state
var current_hp: int = 100
var max_hp: int = 100
var ability_charges: int = 3
var max_ability_charges: int = 3
var facing_dir: float = 1.0
var spawn_position: Vector2 = Vector2.ZERO

# Dodge & invulnerability
var _dodge_timer: float = 0.0
var _dodge_cooldown: float = 0.0
var _perfect_dodge_window_timer: float = 0.0
var _invuln_timer: float = 0.0
var _perfect_dodge_triggered_this_dash: bool = false

# 3-Hit Combo state
var _combo_step: int = 0 # 0 = none, 1..3 = hit index
var _combo_active_timer: float = 0.0
var _combo_chain_timer: float = 0.0
var _combo_queued: bool = false

@onready var visuals: Node2D = $Visuals
@onready var body_poly: Polygon2D = $Visuals/BodyPoly
@onready var scarf_poly: Polygon2D = $Visuals/ScarfPoly
@onready var slash_visual: Polygon2D = $Visuals/SlashVisual
@onready var attack_area: Area2D = $Visuals/AttackArea
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	add_to_group(&"player")
	if hero_data == null:
		hero_data = DEFAULT_HERO_DATA
	_recalculate_metrics()
	max_hp = hero_data.max_hp
	current_hp = max_hp
	max_ability_charges = hero_data.max_ability_charges
	ability_charges = max_ability_charges
	spawn_position = global_position
	if GameStateManager.has_checkpoint:
		global_position = GameStateManager.checkpoint_position
		spawn_position = global_position

	slash_visual.visible = false
	status_label.text = ""
	_emit_hud_state()

func _recalculate_metrics() -> void:
	var h: float = hero_data.jump_height
	var t: float = maxf(hero_data.time_to_apex, 0.15)
	_rise_gravity = (2.0 * h) / (t * t)
	_jump_velocity = -(2.0 * h) / t
	_fall_gravity = _rise_gravity * hero_data.fall_gravity_multiplier

func _emit_hud_state() -> void:
	GlobalSignalBus.health_changed.emit(current_hp, max_hp)
	GlobalSignalBus.ability_charges_changed.emit(ability_charges, max_ability_charges)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_handle_dodge_input()
	_handle_ability_input()
	_handle_attack_input()

	if _dodge_timer > 0.0:
		velocity.x = facing_dir * hero_data.move_speed * 2.15
		velocity.y = 0.0
		_check_perfect_dodge_proximity()
	else:
		_apply_vertical_physics(delta)
		_apply_horizontal_movement(delta)

	move_and_slide()
	_update_visual_feedback()

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_air_jumps_left = 1 if GameStateManager.assist_double_jump else 0
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed(&"jump"):
		# Check one-way platform drop-through (Down + Jump)
		if Input.is_action_pressed(&"move_down") and is_on_floor():
			position.y += 4.0
		else:
			_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	_dodge_timer = maxf(_dodge_timer - delta, 0.0)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	_perfect_dodge_window_timer = maxf(_perfect_dodge_window_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)

	if _combo_active_timer > 0.0:
		_combo_active_timer = maxf(_combo_active_timer - delta, 0.0)
		if _combo_active_timer == 0.0:
			slash_visual.visible = false
			if _combo_queued and _combo_step < 3:
				_combo_queued = false
				_execute_combo_hit(_combo_step + 1)

	if _combo_chain_timer > 0.0:
		_combo_chain_timer = maxf(_combo_chain_timer - delta, 0.0)
		if _combo_chain_timer == 0.0 and _combo_active_timer == 0.0:
			_combo_step = 0

func _apply_vertical_physics(delta: float) -> void:
	# Consume buffered jump via ground/coyote or Assist double jump
	if _jump_buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			velocity.y = _jump_velocity
			_jump_buffer_timer = 0.0
			_coyote_timer = 0.0
		elif _air_jumps_left > 0:
			velocity.y = _jump_velocity * 0.92
			_air_jumps_left -= 1
			_jump_buffer_timer = 0.0
			_show_floating_status(GameStateManager.t("LOMPAT BERGANDA!", "DOUBLE JUMP!"))

	# Variable jump height cut when releasing jump early
	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	if not is_on_floor():
		var g := _fall_gravity if velocity.y > 0.0 else _rise_gravity
		velocity.y = minf(velocity.y + g * delta, _max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

func _apply_horizontal_movement(delta: float) -> void:
	var dir := Input.get_axis(&"move_left", &"move_right")
	if dir != 0.0:
		facing_dir = signf(dir)
		visuals.scale.x = facing_dir
		var target_speed := dir * hero_data.move_speed
		if _combo_active_timer > 0.0:
			target_speed *= 0.55
		velocity.x = move_toward(velocity.x, target_speed, hero_data.move_speed * 14.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, hero_data.move_speed * 16.0 * delta)

func _handle_dodge_input() -> void:
	if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown <= 0.0 and _dodge_timer <= 0.0:
		_dodge_timer = 0.20
		_dodge_cooldown = 0.48
		_perfect_dodge_triggered_this_dash = false
		var assist_mult := 1.35 if GameStateManager.assist_extended_dodge else 1.0
		# Sang Kancil passive: dodge window is 50% larger (hero_data.dodge_window_multiplier = 1.5)
		var perfect_window := hero_data.base_dodge_window * hero_data.dodge_window_multiplier * assist_mult
		_perfect_dodge_window_timer = perfect_window
		_invuln_timer = maxf(_invuln_timer, perfect_window)

func _check_perfect_dodge_proximity() -> void:
	if _perfect_dodge_triggered_this_dash or _perfect_dodge_window_timer <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if node is Node2D and is_instance_valid(node):
			var d := global_position.distance_to((node as Node2D).global_position)
			if d <= 92.0:
				_trigger_perfect_dodge()
				return

func _trigger_perfect_dodge() -> void:
	if _perfect_dodge_triggered_this_dash:
		return
	_perfect_dodge_triggered_this_dash = true
	_invuln_timer = 0.65
	_show_floating_status(GameStateManager.t("ELAK SEMPURNA! (+50% Kancil)", "PERFECT DODGE! (+50% Kancil)"))
	GlobalSignalBus.perfect_dodge_triggered.emit()
	_run_slowmo_pulse()

func _run_slowmo_pulse() -> void:
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.14, true, false, true).timeout
	Engine.time_scale = 1.0

func _handle_Attack_Or_Queue() -> void:
	if _combo_active_timer > 0.0:
		_combo_queued = true
		return
	var next_step := (_combo_step % 3) + 1
	_execute_combo_hit(next_step)

func _handle_attack_input() -> void:
	if Input.is_action_just_pressed(&"attack"):
		_handle_Attack_Or_Queue()

func _execute_combo_hit(step: int) -> void:
	_combo_step = clampi(step, 1, 3)
	_combo_active_timer = 0.16
	_combo_chain_timer = 0.55
	velocity.x = facing_dir * (90.0 + float(_combo_step) * 35.0)

	# Show slash arc with color intensity per combo hit
	slash_visual.visible = true
	match _combo_step:
		1:
			slash_visual.color = Color(1.0, 0.92, 0.45, 0.85)
			slash_visual.scale = Vector2(1.0, 0.9)
		2:
			slash_visual.color = Color(1.0, 0.72, 0.22, 0.9)
			slash_visual.scale = Vector2(1.15, 1.1)
		3:
			slash_visual.color = Color(0.25, 0.95, 0.78, 0.95)
			slash_visual.scale = Vector2(1.38, 1.35)
			_show_floating_status(GameStateManager.t("KOMBO 3x!", "3x FINISHER!"))

	var dmg: int = hero_data.combo_damage[_combo_step - 1]
	var knockback := Vector2(facing_dir * (140.0 + float(_combo_step) * 65.0), -110.0)
	for body: Node2D in attack_area.get_overlapping_bodies():
		if body and body.is_in_group(&"enemies") and body.has_method("take_damage"):
			body.call("take_damage", dmg, knockback)
			GlobalSignalBus.combo_hit_landed.emit(_combo_step)

func _handle_ability_input() -> void:
	if Input.is_action_just_pressed(&"special_ability"):
		deploy_bait_trap()

func deploy_bait_trap() -> bool:
	if ability_charges <= 0:
		_show_floating_status(GameStateManager.t("Tiada Umpan! Cari Keramat Penunggu", "No Traps! Visit a Penunggu Shrine"))
		return false
	ability_charges -= 1
	GlobalSignalBus.ability_charges_changed.emit(ability_charges, max_ability_charges)

	var trap: BaitTrap = BAIT_TRAP_SCENE.instantiate() as BaitTrap
	trap.global_position = global_position + Vector2(facing_dir * 44.0, 0.0)
	get_parent().add_child(trap)
	_show_floating_status(GameStateManager.t("Umpan Dipasang!", "Bait Trap Deployed!"))
	return true

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	if _perfect_dodge_window_timer > 0.0:
		_trigger_perfect_dodge()
		return
	if _invuln_timer > 0.0:
		return

	var final_amount := amount
	if GameStateManager.challenger_mode:
		final_amount = int(ceil(float(amount) * 1.5))

	current_hp = maxi(current_hp - final_amount, 0)
	_invuln_timer = 0.75
	if source_pos != Vector2.ZERO:
		var push_dir := signf(global_position.x - source_pos.x)
		if push_dir == 0.0:
			push_dir = -facing_dir
		velocity = Vector2(push_dir * 260.0, -240.0)

	GlobalSignalBus.health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_respawn_at_checkpoint()

func heal_and_replenish() -> void:
	current_hp = max_hp
	ability_charges = max_ability_charges
	_emit_hud_state()
	_show_floating_status(GameStateManager.t("Restu Penunggu Diterima!", "Penunggu Blessing Restored!"))

func set_checkpoint_pos(pos: Vector2) -> void:
	spawn_position = pos

func _respawn_at_checkpoint() -> void:
	GlobalSignalBus.player_died.emit()
	current_hp = max_hp
	ability_charges = max_ability_charges
	velocity = Vector2.ZERO
	if GameStateManager.has_checkpoint:
		global_position = GameStateManager.checkpoint_position
	else:
		global_position = spawn_position
	_invuln_timer = 1.0
	_emit_hud_state()
	_show_floating_status(GameStateManager.t("Bangkit di Titik Semak", "Respawned at Checkpoint"))

func _update_visual_feedback() -> void:
	if _dodge_timer > 0.0:
		body_poly.color = Color(0.98, 0.92, 0.45, 0.85)
	elif _invuln_timer > 0.0:
		var blink := sin(Time.get_ticks_msec() * 0.03) > 0.0
		body_poly.color = Color(1.0, 0.55, 0.4, 0.75) if blink else Color(0.86, 0.58, 0.24, 1.0)
	else:
		body_poly.color = Color(0.86, 0.58, 0.24, 1.0)

func _show_floating_status(msg: String) -> void:
	if status_label == null:
		return
	status_label.text = msg
	status_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(status_label, "modulate:a", 0.0, 0.35)
