class_name HazardZone
extends Area2D

## Environmental hazard (Kegelapan ink thorns or deep river):
## Deals damage and returns Sang Kancil to the last safe checkpoint or respawn point.

@export var damage: int = 25
@export var teleport_to_checkpoint: bool = true
@export var hazard_label_bm: String = "Duri Kegelapan"
@export var hazard_label_en: String = "Kegelapan Thorns"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		var player := body as PlayerController
		player.take_damage(damage, global_position)
		if teleport_to_checkpoint and player.current_hp > 0:
			if GameStateManager.has_checkpoint:
				player.global_position = GameStateManager.checkpoint_position
			else:
				player.global_position = player.spawn_position
			player.velocity = Vector2.ZERO
	elif body and body.is_in_group(&"enemies") and body.has_method("take_damage"):
		# GDD Section 4.4: "Environmental Combat: Some stage hazards can be used against enemies"
		body.call("take_damage", damage * 2, Vector2(0, -180))
