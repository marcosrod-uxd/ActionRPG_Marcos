extends KinematicBody2D

const EnemyDeathEffect = preload("res://Action RPG Resources/Effects/EnemyDeathEffect.tscn")

enum {
	IDLE,
	WANDER,
	CHASE,
	HIT_STUN
}

export var MAX_SPEED = 60
export var FRICTION = 5
export var ACCELERATION = 15
onready var WANDER_TARGET_RANGE = MAX_SPEED/12
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var state = IDLE

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var animatedSprite = $AnimatedSprite
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, ACCELERATION)
	knockback = move_and_slide(knockback)
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION)
			seek_player()
			print(wanderController.get_time_left())
			if wanderController.get_time_left() == 0:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1,3))
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1,2))

			var direction = global_position.direction_to(wanderController.target_position) 
			velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION)

			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				print(global_position.distance_to(wanderController.target_position))
				state = pick_random_state([IDLE,WANDER])
				wanderController.start_wander_timer(rand_range(1,3))

		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var direction = global_position.direction_to(player.global_position) #player.global_position - global_position).normalized()
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION)
			else:
				state = IDLE
			animatedSprite.flip_h = velocity.x<0 # if (velocity.x <0) flip_h = false else flup_h = true (this flips the sprite)
	
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * 400
	velocity = move_and_slide(velocity)	

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func accelerate_towards_point(point):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction *MAX_SPEED, ACCELERATION)

func _on_Hurtbox_area_entered(area):
	stats.health-= area.damage      #set_health(get_health()-area.damage)
	knockback = area.knockback_vector * 200
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
