class_name BaitTrap
extends Area2D

## Sang Kancil's Special Ability: Deploys a fragrant Keranji fruit snare trap that distracts enemies
## within range for `duration` seconds and stuns lunging bosses on contact.

@export var lure_radius: float = 260.0
@export var duration: float = 5.5
@export var stun_damage: int = 20

var _elapsed: float = 0.0
var _triggered_boss: bool = false

@onready var pulse_ring: Polygon2D = $PulseRing
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group(&"bait_traps")
	body_entered.connect(_on_body_entered)
	_update_label()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var remaining := maxf(duration - _elapsed, 0.0)
	if pulse_ring:
		var s := 1.0 + 0.18 * sin(_elapsed * 7.0)
		pulse_ring.scale = Vector2(s, s)
	if label:
		label.text = "%s (%.1fs)" % [GameStateManager.t("UMPAN KANCIL", "BAIT TRAP"), remaining]

	# Lure all enemies within lure_radius
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		if node is Node2D and is_instance_valid(node):
			var dist := global_position.distance_to((node as Node2D).global_position)
			if dist <= lure_radius and node.has_method("apply_bait_lure"):
				node.call("apply_bait_lure", global_position, 0.6)

	if _elapsed >= duration:
		queue_free()

func _update_label() -> void:
	if label:
		label.text = GameStateManager.t("UMPAN KANCIL", "BAIT TRAP")

func _on_body_entered(body: Node) -> void:
	if _triggered_boss:
		return
	if body and body.is_in_group(&"boss") and body.has_method("on_hit_bait_trap"):
		_triggered_boss = true
		body.call("on_hit_bait_trap", stun_damage)
		queue_free()
