class_name CorruptedEnemy
extends CharacterBody2D

## Kampung Akal corrupted creature:
## - Patrols between patrol_distance left/right of spawn
## - Chases & attacks player on sight
## - Lured into DISTRACTED state by Sang Kancil's Bait Trap (takes 1.5x backstab damage while distracted)
## - Respects Assist Option: slower enemy attacks.

@export var enemy_name_bm: String = "Babi Hutan Kegelapan"
@export var enemy_name_en: String = "Corrupted Boar"
@export var max_hp: int = 44
@export var move_speed: float = 115.0
@export var patrol_distance: float = 130.0
@export var contact_damage: int = 16
@export var is_flying: bool = false

var current_hp: int = 44
var _spawn_pos: Vector2 = Vector2.ZERO
var _patrol_dir: float = 1.0
var _lure_timer: float = 0.0
var _lure_target: Vector2 = Vector2.ZERO
var _hurt_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _hover_phase: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var body_poly: Polygon2D = $Visuals/BodyPoly
@onready var state_label: Label = $StateLabel
@onready var hitbox_area: Area2D = $HitboxArea

func _ready() -> void:
	add_to_group(&"enemies")
	current_hp = max_hp
	_spawn_pos = global_position
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	_update_label()

func _physics_process(delta: float) -> void:
	var speed_mult := 0.62 if GameStateManager.assist_slower_enemies else 1.0
	_lure_timer = maxf(_lure_timer - delta, 0.0)
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta * speed_mult, 0.0)
	_hover_phase += delta * 3.5

	if not is_flying and not is_on_floor():
		velocity.y = minf(velocity.y + 1600.0 * delta, 850.0)
	elif is_flying:
		velocity.y = sin(_hover_phase) * 35.0

	if _hurt_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
	elif _lure_timer > 0.0:
		# Distracted by Sang Kancil's Bait Trap!
		var diff_x := _lure_target.x - global_position.x
		if absf(diff_x) > 18.0:
			var dir := signf(diff_x)
			velocity.x = dir * move_speed * 0.85 * speed_mult
			visuals.scale.x = dir
		else:
			velocity.x = 0.0
	else:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and global_position.distance_to(player.global_position) < 250.0:
			var dir := signf(player.global_position.x - global_position.x)
			if dir != 0.0:
				visuals.scale.x = dir
			velocity.x = dir * move_speed * 1.25 * speed_mult
		else:
			var offset_x := global_position.x - _spawn_pos.x
			if offset_x > patrol_distance:
				_patrol_dir = -1.0
			elif offset_x < -patrol_distance:
				_patrol_dir = 1.0
			visuals.scale.x = _patrol_dir
			velocity.x = _patrol_dir * move_speed * speed_mult

	move_and_slide()
	_check_contact_damage()
	_update_label()

func apply_bait_lure(trap_pos: Vector2, duration: float) -> void:
	_lure_target = trap_pos
	_lure_timer = maxf(_lure_timer, duration)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	var final_dmg := amount
	if _lure_timer > 0.0:
		# Bonus trickster damage against distracted enemies
		final_dmg = int(ceil(float(amount) * 1.5))
	current_hp = maxi(current_hp - final_dmg, 0)
	_hurt_timer = 0.22
	velocity = knockback
	if body_poly:
		body_poly.modulate = Color(1.0, 0.35, 0.35, 1.0)
		var tw := create_tween()
		tw.tween_property(body_poly, "modulate", Color(1, 1, 1, 1), 0.2)

	if current_hp <= 0:
		queue_free()

func _check_contact_damage() -> void:
	if _lure_timer > 0.0 or _hurt_timer > 0.0 or _attack_cooldown > 0.0:
		return
	for body: Node2D in hitbox_area.get_overlapping_bodies():
		if body is PlayerController:
			_attack_cooldown = 0.85
			(body as PlayerController).take_damage(contact_damage, global_position)

func _on_hitbox_body_entered(body: Node) -> void:
	if _lure_timer > 0.0 or _hurt_timer > 0.0 or _attack_cooldown > 0.0:
		return
	if body is PlayerController:
		_attack_cooldown = 0.85
		(body as PlayerController).take_damage(contact_damage, global_position)

func _update_label() -> void:
	if state_label == null:
		return
	var title := GameStateManager.t(enemy_name_bm, enemy_name_en)
	if _lure_timer > 0.0:
		state_label.text = "❓ %s [%s] (%d/%d)" % [title, GameStateManager.t("TERPEDAYA", "DISTRACTED"), current_hp, max_hp]
		state_label.modulate = Color(1.0, 0.92, 0.35, 1.0)
	else:
		state_label.text = "%s (%d/%d)" % [title, current_hp, max_hp]
		state_label.modulate = Color(0.92, 0.72, 0.98, 0.9)
