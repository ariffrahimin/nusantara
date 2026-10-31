class_name BossBuaya
extends CharacterBody2D

## Region 1 Boss: Sang Buaya Hitam (Kegelapan-Corrupted Crocodile King of Kampung Akal)
## - Phase cycle: Stalking -> Telegraph Jaw Lunge -> Lunge Dash -> Recover
## - Trickster Synergy: If Sang Buaya Hitam lunges into Sang Kancil's Bait Trap, he chomps the trap,
##   takes trap stun damage, and becomes STUNNED for 3.2s (taking 1.5x combo damage!).

@export var max_hp: int = 240
@export var base_speed: float = 135.0
@export var lunge_speed: float = 410.0

enum State { STALK, TELEGRAPH, LUNGE, STUNNED, RECOVER, DEFEATED }

var current_hp: int = 240
var _state: State = State.STALK
var _state_timer: float = 2.0
var _facing: float = -1.0
var _lure_pos: Vector2 = Vector2.ZERO
var _has_lure: bool = false

@onready var visuals: Node2D = $Visuals
@onready var body_poly: Polygon2D = $Visuals/BodyPoly
@onready var jaw_poly: Polygon2D = $Visuals/JawPoly
@onready var hitbox_area: Area2D = $HitboxArea
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"boss")
	current_hp = max_hp
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	_broadcast_boss_hp(true)
	_update_status_label()

func _physics_process(delta: float) -> void:
	if _state == State.DEFEATED:
		return

	var speed_mult := 0.65 if GameStateManager.assist_slower_enemies else 1.0
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1600.0 * delta, 900.0)

	_state_timer -= delta * speed_mult
	var player := get_tree().get_first_node_in_group(&"player") as Node2D

	match _state:
		State.STALK:
			var target_x := global_position.x
			if _has_lure:
				target_x = _lure_pos.x
			elif player != null:
				target_x = player.global_position.x
			var diff := target_x - global_position.x
			if absf(diff) > 20.0:
				_facing = signf(diff)
				visuals.scale.x = _facing
				velocity.x = _facing * base_speed * speed_mult
			else:
				velocity.x = 0.0
			if _state_timer <= 0.0:
				_enter_state(State.TELEGRAPH, 0.75)

		State.TELEGRAPH:
			velocity.x = 0.0
			if player != null and not _has_lure:
				var d := signf(player.global_position.x - global_position.x)
				if d != 0.0:
					_facing = d
					visuals.scale.x = _facing
			jaw_poly.rotation_degrees = -22.0 * _facing
			if _state_timer <= 0.0:
				jaw_poly.rotation_degrees = 0.0
				_enter_state(State.LUNGE, 0.65)

		State.LUNGE:
			velocity.x = _facing * lunge_speed * speed_mult
			_damage_overlapping_player(24)
			if _state_timer <= 0.0:
				_has_lure = false
				_enter_state(State.RECOVER, 1.1)

		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _state_timer <= 0.0:
				_has_lure = false
				_enter_state(State.STALK, 1.6)

		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _state_timer <= 0.0:
				_enter_state(State.STALK, 1.8)

	move_and_slide()
	_update_status_label()

func _enter_state(new_state: State, duration: float) -> void:
	_state = new_state
	_state_timer = duration
	match _state:
		State.TELEGRAPH:
			body_poly.color = Color(0.65, 0.16, 0.36, 1.0)
		State.LUNGE:
			body_poly.color = Color(0.82, 0.18, 0.28, 1.0)
		State.STUNNED:
			body_poly.color = Color(0.32, 0.68, 0.58, 1.0)
		_:
			body_poly.color = Color(0.16, 0.28, 0.22, 1.0)

func apply_bait_lure(trap_pos: Vector2, _duration: float) -> void:
	if _state == State.DEFEATED or _state == State.STUNNED:
		return
	_lure_pos = trap_pos
	_has_lure = true
	var d := signf(trap_pos.x - global_position.x)
	if d != 0.0:
		_facing = d
		visuals.scale.x = _facing

func on_hit_bait_trap(trap_damage: int) -> void:
	if _state == State.DEFEATED:
		return
	_enter_state(State.STUNNED, 3.2)
	take_damage(trap_damage, Vector2(-_facing * 120.0, -140.0))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _state == State.DEFEATED:
		return
	var mult := 1.5 if _state == State.STUNNED else 1.0
	var final_dmg := int(ceil(float(amount) * mult))
	current_hp = maxi(current_hp - final_dmg, 0)
	velocity.x = knockback.x * 0.35
	_broadcast_boss_hp(true)

	if current_hp <= 0:
		_defeat_boss()

func _defeat_boss() -> void:
	_state = State.DEFEATED
	velocity = Vector2.ZERO
	body_poly.color = Color(0.28, 0.85, 0.68, 0.75)
	_broadcast_boss_hp(false)
	_update_status_label()
	GlobalSignalBus.boss_defeated.emit()

func _damage_overlapping_player(dmg: int) -> void:
	for body: Node2D in hitbox_area.get_overlapping_bodies():
		if body is PlayerController:
			(body as PlayerController).take_damage(dmg, global_position)

func _on_hitbox_body_entered(body: Node) -> void:
	if _state == State.DEFEATED or _state == State.STUNNED:
		return
	if body is PlayerController:
		(body as PlayerController).take_damage(18, global_position)

func _broadcast_boss_hp(vis: bool) -> void:
	var bname := GameStateManager.t("Sang Buaya Hitam (Raja Muara Kegelapan)", "Sang Buaya Hitam (Corrupted Crocodile King)")
	GlobalSignalBus.boss_health_changed.emit(bname, current_hp, max_hp, vis)

func _update_status_label() -> void:
	if status_label == null:
		return
	match _state:
		State.TELEGRAPH:
			status_label.text = GameStateManager.t("⚠️ AWAS! Rahang Membuka (Elak / Pasang Umpan!)", "⚠️ JAW LUNGE INCOMING! (Dodge or Place Bait Trap!)")
		State.STUNNED:
			status_label.text = GameStateManager.t("💫 TERPEDAYA OLEH UMPAN! Serang Sekarang! (1.5x)", "💫 STUNNED BY BAIT TRAP! Attack Now! (1.5x)")
		State.DEFEATED:
			status_label.text = GameStateManager.t("✨ Sang Buaya Pulih Daripada Kegelapan! Gerbang Terbuka!", "✨ Sang Buaya Purified! Victory Gate Unlocked!")
		_:
			status_label.text = GameStateManager.t("Sang Buaya Hitam (%d/%d HP)" % [current_hp, max_hp], "Sang Buaya Hitam (%d/%d HP)" % [current_hp, max_hp])
