extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2
const ATTACK_DURATION = 0.3

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_jumping = false
var is_dashing = false
var dash_timer = 0.0
var can_dash = true
var is_attacking = false
var attack_timer = 0.0
var can_attack = true
var is_climbing = false
var can_climb = false # This would be set by collision with a climbable object
var is_interacting = false # For dialogue or object interaction

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Gravity
	if not is_on_floor() and not is_climbing:
		velocity.y += gravity * delta

	# Handle input
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Movement
	if not is_dashing and not is_attacking and not is_interacting:
		if is_climbing:
			velocity.x = 0
			velocity.y = input_direction.y * SPEED
			if not can_climb: # If somehow detached from climbable surface
				is_climbing = false
		else:
			velocity.x = input_direction.x * SPEED
			if input_direction.x != 0:
				animated_sprite.flip_h = input_direction.x < 0
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")
	elif is_dashing:
		# Dash movement is handled separately
		pass
	elif is_attacking:
		# Player might be stationary or have limited movement during attack
		velocity.x = 0
	elif is_interacting:
		velocity.x = 0
		velocity.y = 0
		animated_sprite.play("idle")

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_dashing and not is_attacking and not is_interacting and not is_climbing:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		animated_sprite.play("jump")

	# Dash
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and not is_attacking and not is_climbing and not is_interacting:
		is_dashing = true
		can_dash = false # Prevent spamming dash
		dash_timer = DASH_DURATION
		velocity.x = animated_sprite.scale.x * DASH_SPEED # Dash in current facing direction
		velocity.y = 0 # Stop vertical movement during dash
		animated_sprite.play("dash")

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0 # Stop horizontal dash velocity
			# Reset can_dash after a cooldown (not implemented here for brevity)

	# Attack
	if Input.is_action_just_pressed("attack") and can_attack and not is_dashing and not is_attacking and not is_climbing and not is_interacting:
		is_attacking = true
		can_attack = false
		attack_timer = ATTACK_DURATION
		animated_sprite.play("attack")

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			# Reset can_attack after cooldown

	# Climbing (simplified)
	if Input.is_action_just_pressed("climb") and can_climb and not is_dashing and not is_attacking and not is_interacting:
		is_climbing = not is_climbing # Toggle climbing

	# Interaction (simplified)
	if Input.is_action_just_pressed("interact") and not is_dashing and not is_attacking and not is_climbing:
		is_interacting = not is_interacting # Toggle interaction

	# Animation updates based on combined states
	if not is_dashing and not is_attacking and not is_interacting:
		if is_climbing:
			animated_sprite.play("climb") # Assuming a climb animation
		elif not is_on_floor():
			if velocity.y > 0:
				animated_sprite.play("fall")
			elif velocity.y < 0 and is_jumping:
				animated_sprite.play("jump") # Could be separate rising jump animation
		elif velocity.x != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

	# Reset jump flag when landing
	if is_on_floor() and is_jumping:
		is_jumping = false
		can_dash = true # Example: reset dash on landing
		can_attack = true # Example: reset attack on landing

	move_and_slide()
