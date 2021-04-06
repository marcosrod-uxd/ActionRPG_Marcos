extends KinematicBody2D

const PlayerHurtSound = preload("res://Action RPG Resources/Music and Sounds/PlayerHurtSound.tscn")

export var FRICTION = 15
export var ACCELERATION = 15
export var MAX_SPEED = 100

enum {
	INPUT,
	ROLL,
	ATTACK
}

var state = INPUT
var velocity = Vector2.ZERO
var input_vector = Vector2.DOWN #input_vector initialized as down to match character default direction. this is for setdir()
var input_direction = Vector2.DOWN
var stats = PlayerStats #accesses autoloaded singleton "PlayerStats". Sort of like a global script

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = input_direction
	setdir()

func _process(_delta):
	match state:
		INPUT:
			input_state()
		ROLL:
			roll_state()
		ATTACK:
			attack_state()

func input_state():
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if (input_vector != Vector2.ZERO):
		setdir()
		move()
	else:
		idle()

	if Input.is_action_just_pressed("Attack"):
		state = ATTACK
	
	if Input.is_action_just_pressed("Roll"):
		velocity = input_direction*180
		state = ROLL

func attack_state():
	animationState.travel("Attack")

func roll_state():
	animationState.travel("Roll")
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION*.1)
	velocity = move_and_slide(velocity)

func setdir():
	input_direction = input_vector
	swordHitbox.knockback_vector = input_direction
	animationTree.set("parameters/Attack/blend_position", input_direction)
	animationTree.set("parameters/Idle/blend_position", input_direction)
	animationTree.set("parameters/Run/blend_position", input_direction)
	animationTree.set("parameters/Roll/blend_position", input_direction)

func move():
	animationState.travel("Run")

	velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION)
	velocity = move_and_slide(velocity)

func idle():
	animationState.travel("Idle")

	velocity = velocity.move_toward(Vector2.ZERO, FRICTION)
	velocity = move_and_slide(velocity)

func animation_finished():
	state = INPUT

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.5) 
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)

func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
