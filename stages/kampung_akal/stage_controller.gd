class_name StageController
extends Node2D

## Manages a Kampung Akal stage:
## - Syncs current_stage_index in GameStateManager
## - Draws atmospheric Nusantara backdrop + Kegelapan encroaching horizon
## - Enforces bottom pit safety respawn if player falls below stage floor.

@export var stage_index: int = 1
@export var pit_y_threshold: float = 820.0
@export var sky_color: Color = Color(0.11, 0.19, 0.18, 1.0)

@onready var player: PlayerController = get_node_or_null("Player") as PlayerController

func _ready() -> void:
	GameStateManager.current_stage_index = stage_index
	RenderingServer.set_default_clear_color(sky_color)

func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y > pit_y_threshold:
		player.take_damage(20, player.global_position + Vector2(0, 40))
		if GameStateManager.has_checkpoint:
			player.global_position = GameStateManager.checkpoint_position
		else:
			player.global_position = player.spawn_position
		player.velocity = Vector2.ZERO
