 extends KinematicBody2D

export var FRICTION = 10

var knockback = Vector2.ZERO

onready var stats = $Stats

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION)
	knockback = move_and_slide(knockback)

func _on_Hurtbox_area_entered(area):
	stats.health-= area.damage
	knockback = area.knockback_vector * 200

func _on_Stats_no_health():
	queue_free()
