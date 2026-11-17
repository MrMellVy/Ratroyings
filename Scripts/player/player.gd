extends CharacterBody2D

class_name Player

@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D
var world_camera: Camera2D
@onready var skill_damage_zone: Area2D = $SkillDamageZone
@onready var damageLabelIndicator = $DamageLabelIndicator

# Horizontal Movement
@export_category("Movement")
@export_range(50, 500) var maxSpeed: float = 200.0
@export_range(0, 4) var timeToMaxSpeed: float = 0.2
@export_range(0, 4) var timeToZeroSpeed: float = 0.2
@export var directionalSnap: bool = false
@export var runningModifier: bool = false

# Jumping
@export_category("Jumping and Gravity")
@export_range(0, 20) var jumpHeight: float = 2.0
@export_range(0, 4) var jumps: int = 1
@export_range(0, 100) var gravityScale: float = 20.0
@export_range(0, 1000) var terminalVelocity: float = 500.0
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
@export var VariableJumpHeight: bool = true
@export_range(1, 10) var jumpVariable: float = 2
@export_range(0, 0.5) var coyoteTime: float = 0.2
@export_range(0, 0.5) var jumpBuffering: float = 0.2
@onready var jump_sound: AudioStreamPlayer = $JumpSound

# Extra Mech
@export_category("Wall Jumping")
@export var wallJump: bool = false
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
@export_range(0, 90) var wallKickAngle: float = 60.0
@export_range(1, 20) var wallSliding: float = 1.0
@export var wallLatching: bool = false
@export var wallLatchingModifer: bool = false

# Dashing
@export_category("Dashing")
@export_enum("None", "Horizontal", "Vertical", "Four Way") var dashType: int
@export_range(0, 10) var dashes: int = 1
@export var dashCancel: bool = true
@export_range(1.5, 4) var dashLength: float = 2.5

# Animation
@export_category("Animations")
@export var run: bool
@export var jump: bool
@export var idle: bool
@export var walk: bool
@export var slide: bool
@export var latch: bool
@export var falling: bool

#Attack
@onready var deal_damage_zone = $DealDamageZone
@onready var slash_sfx: AudioStreamPlayer = $SlashSFX

#Shake Camera Motion
@export var shake = false
@export var max_shake_duration = 1.0
@export var shake_duration = 0.0
@export var time: int = 0

# Dev Variable and const
var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpCount: int = 0
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true
var dashing: bool = false
var dashCount: int
const MAX_JUMPS: int = 2

var twoWayDashHorizontal
var twoWayDashVertical

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true)

var gdelta: float = 1

var dset = false

var colliderScaleLockY
var colliderPosLockY

var latched
var wasLatched

var attack_type: String
var current_attack: bool

var base_health_max = 100
var damage_bonus = 0

var health = 100
var health_max = 100
var health_min = 0
var can_take_damage: bool
var defeat: bool
var is_hurt: bool = false
var is_use_skill: bool = false
var can_use_skill: bool = true
var skill_hit_active: bool = false

var anim
var col
var animScaleLock : Vector2

# Input Variable
var leftHold
var leftTap
var leftRelease
var rightHold
var rightTap
var rightRelease
var jumpTap
var jumpRelease
var runHold
var latchHold
var dashTap

func _ready() -> void:
	Global.playerBody = self
	add_to_group("player")
	current_attack = false
	defeat = false
	can_take_damage = true
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	Global.playerAlive = true
	deal_damage_zone.get_node("CollisionShape2D2").disabled = true

	_updateData()
	if get_tree().current_scene == self:
		world_camera = $TestCamera
		world_camera.make_current()
	else:
		if has_node("OwnPlat") and has_node("Enemy_dummy") and has_node("TestCamera"):
			$OwnPlat.queue_free()
			$Enemy_dummy.queue_free()
			$TestCamera.queue_free()
	
func _updateData():
	acceleration = maxSpeed / timeToMaxSpeed
	deceleration = -maxSpeed / timeToZeroSpeed
	
	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps
	
	dashMagnitude = maxSpeed * dashLength
	dashCount = dashes
	
	maxSpeedLock = maxSpeed
	
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	if timeToMaxSpeed == 0:
		instantAccel = true
		timeToMaxSpeed = 1
	elif timeToMaxSpeed < 0:
		timeToMaxSpeed = abs(timeToMaxSpeed)
		instantAccel = false
	else :
		instantAccel = false
		
	if timeToZeroSpeed == 0:
		instantStop = true
		timeToZeroSpeed = 1
	elif timeToZeroSpeed < 0:
		timeToZeroSpeed = abs(timeToZeroSpeed)
		instantStop = false
	else :
		instantStop = false
		
	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0
		
	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)
	
	if directionalSnap:
		instantAccel = true
		instantStop = true
		
	twoWayDashHorizontal = false
	twoWayDashVertical = false
	if dashType == 0:
		pass
	if dashType == 1:
		twoWayDashHorizontal = true
	elif dashType == 2:
		twoWayDashVertical = true
	elif dashType == 3:
		twoWayDashHorizontal = true
		twoWayDashVertical = true
		
func _process(_delta) -> void:
	if defeat or is_hurt: return
	# Direction
	if can_wall_interact() and !is_on_floor() and latch and wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
		latched = true
	else :
		latched = false
		wasLatched = true
		_setLatch(0.2, false)
		
	#flip_sprite btw
	if rightHold and !latched and !skill_hit_active:
		toggle_flip_sprite(1)
	if leftHold and !latched and !skill_hit_active:
		toggle_flip_sprite(-1)
		
	# Run
	if !current_attack:
		if run and idle and !dashing:
			var actual_speed = abs(get_real_velocity().x)
			if actual_speed > 0.1 and is_on_floor() and !is_on_wall():
				anim.speed_scale = actual_speed / 150.0
				anim.play("run")
			elif is_on_floor():
				anim.speed_scale = 1.0
				anim.play("idle")
	
	# Jump
	if !current_attack:
		if velocity.y < 0 and jump and !dashing:
			anim.speed_scale = 1
			if !is_on_floor() and jumpCount < jumps -1: #Don't have double jump anim so print.
				anim.play("jump")
				print("double jump!")
			else:
				anim.play("jump")

		if velocity.y > 40 and falling and !dashing:
			anim.speed_scale = 1
			anim.play("falling")
		
	if !current_attack and (latch and slide):
		# Wall slide & latch
		if latched and !wasLatched:
			anim.speed_scale = 1
			anim.play("latch")
		if can_wall_interact() and velocity.y > 0 and slide and anim.animation != "slide" and wallSliding != 1:
			anim.speed_scale = 1
			anim.play("slide")
	
	# Dashing
	if dashing and !current_attack:
			anim.speed_scale = 1
			anim.play("dash")

func _physics_process(delta) -> void:
	Global.playerDamageZone = deal_damage_zone
	Global.playerHitbox = $PlayerHitbox
	if !dset:
		gdelta = delta
		dset = true
	if !defeat:
		if !current_attack and !is_use_skill and !skill_hit_active:
				#if Input.is_action_just_pressed("skill_attack") and is_on_floor():
					#attack_type = "skill"
					#perform_skill_a()
				if Input.is_action_just_pressed("attack"):
					current_attack = true
					#check for dash too.
					if dashing:
						attack_type = "dash"
					elif is_on_floor():
						attack_type = "single"
					else:
						attack_type = "air"
					set_damage(attack_type)
					handle_attack_animation(attack_type)
				#elif Input.is_action_just_pressed("double"):
					#current_attack = true
					#attack_type = "double" if is_on_floor() else "air"
					#set_damage(attack_type)
					#handle_attack_animation(attack_type)
		# Input Detection
		leftHold = Input.is_action_pressed("left")
		rightHold = Input.is_action_pressed("right")
		leftTap = Input.is_action_just_pressed("left")
		rightTap = Input.is_action_just_pressed("right")
		leftRelease = Input.is_action_just_released("left")
		rightRelease = Input.is_action_just_released("right")
		jumpTap = Input.is_action_just_pressed("jump")
		jumpRelease = Input.is_action_just_released("jump")
		latchHold = Input.is_action_pressed("latch")
		dashTap = Input.is_action_just_pressed("dash")
		
		# L/R Movement
		if rightHold and leftHold and movementInputMonitoring:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = -0.1
		elif rightHold and movementInputMonitoring.x:
			if velocity.x > maxSpeed or instantAccel:
				velocity.x = maxSpeed
			else:
				velocity.x += acceleration * delta
			if velocity.x < 0:
				if !instantStop:
					_decelerate(delta, false)
				else:
					velocity.x = -1
		elif leftHold and movementInputMonitoring.y:
			if velocity.x < -maxSpeed or instantAccel:
				velocity.x = -maxSpeed
			else:
				velocity.x -= acceleration * delta
			if velocity.x > 0:
				if !instantStop:
					_decelerate(delta, false)
				else:
					velocity.x = 0.1
					
		if velocity.x > 0:
			wasMovingR = true
		elif velocity.x < 0:
			wasMovingR = false
			
		if rightTap:
			wasPressingR = true
		if leftTap:
			wasPressingR = false
			
		if runningModifier:
			maxSpeed = maxSpeedLock / 2
		elif is_on_floor(): 
			maxSpeed = maxSpeedLock
			
		if !(leftHold or rightHold) or is_use_skill:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0
				
		# Jump, Gravity, and wall interaction. To make the double jump work, put "2" on the inspector "jumps"
		if velocity.y > 0:
			appliedGravity = gravityScale * descendingGravityFactor
		else:
			appliedGravity = gravityScale
			
		if can_wall_interact():
			appliedTerminalVelocity = terminalVelocity / wallSliding
			if wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
				appliedGravity = 0
				
				if velocity.y < 0:
					velocity.y += 50
				if velocity.y > 0:
					velocity.y = 0
					
				if wallLatchingModifer and latchHold and movementInputMonitoring == Vector2(true, true):
					velocity.x = 0
					
			elif wallSliding != 1 and velocity.y > 0:
				appliedGravity = appliedGravity / wallSliding
		elif !can_wall_interact():
			appliedTerminalVelocity = terminalVelocity
			
		if gravityActive:
			if velocity.y < appliedTerminalVelocity:
				velocity.y += appliedGravity
			elif velocity.y > appliedTerminalVelocity:
					velocity.y = appliedTerminalVelocity
					
		if VariableJumpHeight and jumpRelease and velocity.y < 0:
			velocity.y = velocity.y / jumpVariable
			
		if jumps >= 1:
			if !is_on_floor() and !can_wall_interact():
				if coyoteTime > 0:
					coyoteActive = true
					_coyoteTime()
					
			if jumpTap and !can_wall_interact():
				if coyoteActive:
					coyoteActive = false
					_jump()
				elif is_on_floor():
					_jump()
				elif jumpCount > 0: #for double jump
					_jump()
					
				if jumpBuffering > 0 and !is_on_floor():
					jumpWasPressed = true
					_bufferJump()

			elif jumpTap and can_wall_interact() and !is_on_floor():
				if wallJump and !latched:
					_wallJump()
				elif wallJump and latched:
					_wallJump()
			elif jumpTap and is_on_floor():
				_jump()
				
			if is_on_floor():
				jumpCount = jumps
				if coyoteTime > 0:
					coyoteActive = true
				else:
					coyoteActive = false
				if jumpWasPressed:
					_jump()
					

			
		# Dashing
		if is_on_floor():
			dashCount = dashes
		if twoWayDashHorizontal and dashTap and dashCount > 0:
			var dTime = 0.0625 * dashLength
			if wasPressingR:
				velocity.y = 0
				velocity.x = dashMagnitude
				_pauseGravity(dTime)
				_dashingTime(dTime)
				dashCount += -1
				movementInputMonitoring = Vector2(false, false)
				_inputPauseReset(dTime)
			else:
				velocity.y = 0
				velocity.x = -dashMagnitude
				_pauseGravity(dTime)
				_dashingTime(dTime)
				dashCount += -1
				movementInputMonitoring = Vector2(false, false)
				_inputPauseReset(dTime)
			if current_attack and (attack_type == "single"): #or attack_type == "double"):
				attack_type = "dash"
				set_damage(attack_type)
				handle_attack_animation(attack_type)
		if dashing and velocity.x > 0 and leftTap and dashCancel:
			velocity.x = 0
		if dashing and velocity.x < 0 and rightTap and dashCancel:
			velocity.x = 0
		check_hitbox()
	if shake:
		if world_camera == null or not is_instance_valid(world_camera):
			world_camera = get_viewport().get_camera_2d()
		
		if world_camera:
			time += 1
			shake_duration -= delta
			
			var final_pos = Vector2(sin(time) * 1, sin(time) * 2)
			world_camera.offset = lerp(world_camera.offset, final_pos, 0.2)
			
			if shake_duration <= 0.0:
				shake = false
				time = 0
				world_camera.offset = Vector2.ZERO
				
		else:
			shake = false
			time = 0
	move_and_slide()
	
func check_hitbox():
	if !can_take_damage or defeat:
		return
	var hitbox_areas = $PlayerHitbox.get_overlapping_areas()
	for hitbox in hitbox_areas:
		var parent_node = hitbox.get_parent()
		if parent_node == self:
			continue
			
		if parent_node.is_in_group("enemies"):
			if "is_dealing_damage" in parent_node and "has_dealt_damage" in parent_node:
				if parent_node.is_dealing_damage == true and parent_node.has_dealt_damage == false:
					var dir = sign(global_position.x - parent_node.global_position.x)
					
					var damage = Global.EnemyDamageAmount
					if parent_node is EnemyAir:
						damage = Global.EnemyAirDamageAmount
					var is_boss: bool = parent_node is BossRat or "boss" in parent_node.name
					take_damage(damage, dir, is_boss)
					parent_node.has_dealt_damage = true
					break

func take_damage(value, push_direction, is_boss: bool = false):
	if defeat or value <= 0 or !can_take_damage: 
		return
	health -= value
	can_take_damage = false
	print("player health: ", health)
	if is_boss:
		velocity.x = push_direction * 600.0
		velocity.y = -350
		
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(0.4)
		shake = true
		shake_duration = max_shake_duration * 1.0
	else:
		velocity.x = push_direction * 200
		velocity.y = 200
		shake = true
		shake_duration = max_shake_duration
	
	if health <= 0:
		health = 0
		defeat = true
		handle_defeat_animation()
	else:
		handle_hurt_animation()
		damageLabelIndicator.show_damage_label(-value)
		take_damage_cooldown(0.5)

func handle_hurt_animation():
	is_hurt = true
	current_attack = false
	is_use_skill = false
	PlayerSprite.play("hit")
	$AnimationPlayer.play("Damage_flick")
	await PlayerSprite.animation_finished
	is_hurt = false

func handle_defeat_animation():
	velocity = Vector2.ZERO
	PlayerSprite.play("defeat")
	BgmManager.play_defeated()
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	tween.tween_property(world_camera, "zoom", Vector2(7.0,7.0), 1.5).set_trans(Tween.TRANS_SINE)
	await  tween.finished
	
	if world_camera == null or not is_instance_valid(world_camera):
		world_camera = get_viewport().get_camera_2d()
		
	await get_tree().create_timer(3.5).timeout
	Global.playerAlive = false
	await get_tree().create_timer(2.0).timeout
	self.queue_free()
	
func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false
	
func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount += -1
	
func _jump():
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount += -1
		jumpWasPressed = false
		jump_sound.play()
		
func _wallJump():
	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	velocity.y = -verticalWallKick
	var dir = 1
	if wallLatchingModifer and latchHold:
		dir = -1
	if wasMovingR:
		velocity.x = -horizontalWallKick  * dir
	else:
		velocity.x = horizontalWallKick * dir
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)
		
func _setLatch(delay, setBool):
	await get_tree().create_timer(delay).timeout
	wasLatched = setBool
			
func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)
	
func _decelerate(delta, vertical):
	if !vertical:
		if (abs(velocity.x) > 0) and (abs(velocity.x) <= abs(deceleration * delta)):
			velocity.x = 0 
		elif velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta
		
func _pauseGravity(time):
	gravityActive = false
	await get_tree().create_timer(time).timeout
	gravityActive = true

func _dashingTime(time):
	dashing = true
	await get_tree().create_timer(time).timeout
	dashing = false
	if !is_on_floor():
		velocity.y = -gravityScale * 10


#Attack 
func handle_attack_animation(attack_type):
	if current_attack:
		PlayerSprite.speed_scale = 1.0
		var random_vari = randi_range(1, 3)
		var animation = str(attack_type, "_attack_", random_vari)
		PlayerSprite.play(animation)
		slash_sfx.play()
		toggle_damage_collisions(attack_type)
		#FailSafe
		if PlayerSprite.sprite_frames.has_animation(animation):
			PlayerSprite.play(animation)
		else:
			var fallback_anim = str(attack_type, "_attack")
			if PlayerSprite.sprite_frames.has_animation(fallback_anim):
				PlayerSprite.play(fallback_anim)
			else:
				print("Animation not found -> ", animation, " or ", fallback_anim)
				current_attack = false
				
func toggle_damage_collisions(attack_type):
	deal_damage_zone.get_node("CollisionShape2D2").disabled = false

func toggle_flip_sprite(dir):
	if dir == 1:
		PlayerSprite.flip_h = false
		if !skill_hit_active:
			deal_damage_zone.scale.x = 1
	elif dir == -1:
		PlayerSprite.flip_h = true
		if !skill_hit_active:
			deal_damage_zone.scale.x = -1

func _on_animated_sprite_2d_animation_finished() -> void:
	if current_attack and not is_use_skill and (PlayerSprite.animation.ends_with("attack") or ("_attack_" in PlayerSprite.animation)):
		current_attack = false
		deal_damage_zone.get_node("CollisionShape2D2").disabled = true

func set_damage(attack_type):
	var current_damage_to_deal: int
	if attack_type == "single":
		current_damage_to_deal = 8
	#elif attack_type == "double":
		#current_damage_to_deal = 16
	elif attack_type == "air":
		current_damage_to_deal = 20
	elif attack_type == "dash":
		current_damage_to_deal = 16
	elif attack_type == "skill":
		current_damage_to_deal = 15

	Global.playerDamageAmount = current_damage_to_deal + damage_bonus
	
func apply_wave_stats(wave_number: int):
	# Calculate math man. (+0 on wave 1, +5 on wave 2, +10 on wave 3...)
	var bonus_stats = (wave_number - 1) * 5
	health_max = base_health_max + bonus_stats
	health = health_max 
	damage_bonus = bonus_stats
	
	print("Level Up, Max HP: ", health_max, ", Bonus Damage: +", damage_bonus)
	
func _input(event: InputEvent) -> void:
	#this function it's for going down one way platform, though is still that basic.
	if (event.is_action_pressed("down")):
		position.y += 1

#For the player not jumping on the world border
func can_wall_interact() -> bool:
	if !is_on_wall():
		return false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and collider.is_in_group("Border"):
			return false
	return true

func heal(amount: int) -> void:
	health += amount
	health = min(health, health_max)
	damageLabelIndicator.show_damage_label(amount)
	print("Healed for ", amount, "! Current HP: ", health)

func perform_skill_a():
	is_use_skill = true
	current_attack = true
	PlayerSprite.speed_scale = 1.0
	movementInputMonitoring = Vector2(false, false)
	
	var prev_grav = gravityActive
	gravityActive = false
	velocity = Vector2.ZERO
	
	var ori_damage_zone_pos = deal_damage_zone.position
	var ori_zoom = world_camera.zoom
	
	var zoom_tween = create_tween()
	zoom_tween.tween_property(world_camera, "zoom", ori_zoom * 1.5, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	PlayerSprite.play("single_attack_3") # Still placeholder?
	slash_sfx.play()
	await get_tree().create_timer(1.0).timeout
	
	if !is_use_skill or defeat or !is_on_floor():
		gravityActive = prev_grav
		movementInputMonitoring = Vector2(true, true)
		var reset_tween = create_tween()
		reset_tween.tween_property(world_camera,"zoom", ori_zoom, 0.3)
		set_collision_mask_value(2, true)
		return

	var ori_smooth_enabled = world_camera.position_smoothing_enabled
	var ori_smooth_speed = world_camera.position_smoothing_speed
	
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 10.0

	attack_type = "skill"
	set_damage(attack_type)
	PlayerSprite.play("dash_attack") # Placeholder?
	slash_sfx.play()
	
	var dir = 1 if not PlayerSprite.flip_h else -1

	skill_hit_active = true
	var saved_global_pos = deal_damage_zone.global_position
	deal_damage_zone.top_level = true
	deal_damage_zone.global_position = saved_global_pos
	
	set_collision_mask_value(2, false)
	set_collision_layer_value(1, false)
	
	velocity.x = maxSpeed * 3.0 * dir

	# Stop the dash after 0.5 seconds, but do not block the skill hit loop.
	get_tree().create_timer(0.5).timeout.connect(func():
		velocity.x = 0
		gravityActive = prev_grav
		movementInputMonitoring = Vector2(true,true)
		is_use_skill = false
	)

	await trigger_still_zone_skill()

	skill_hit_active = false
	current_attack = false
	is_use_skill = false
	movementInputMonitoring = Vector2(true, true)
	gravityActive = prev_grav

	deal_damage_zone.top_level = false
	deal_damage_zone.position = ori_damage_zone_pos
	deal_damage_zone.scale.x = -1 if PlayerSprite.flip_h else 1
	set_collision_mask_value(2, true)
	set_collision_layer_value(1, true)

	var zoom_out_tween = create_tween()
	zoom_out_tween.set_parallel(true)
	zoom_out_tween.tween_property(world_camera, "zoom", ori_zoom, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom_out_tween.tween_property(world_camera, "position_smoothing_speed", 25.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await zoom_out_tween.finished
	if is_instance_valid(world_camera):
		world_camera.position_smoothing_enabled = ori_smooth_enabled
		world_camera.position_smoothing_speed = ori_smooth_speed
	


func trigger_still_zone_skill() -> void:
	var skill_shape = deal_damage_zone.get_node("SkillCollisionShape")

	var hit_count = 3
	var hit_active_time = 0.10
	var delay_between_hits = 0.2 # lower, faster hits

	for i in range(hit_count):
		skill_shape.set_deferred("disabled", false)
		await get_tree().physics_frame

		for area in deal_damage_zone.get_overlapping_areas():
			var parent_node = area.get_parent()
			if parent_node is Enemy:
				if parent_node.has_method("take_damage"):
					parent_node.take_damage(Global.playerDamageAmount)

		await get_tree().create_timer(hit_active_time).timeout
		skill_shape.set_deferred("disabled", true)

		if i < hit_count - 1:
			await get_tree().create_timer(delay_between_hits).timeout

func try_perform_skill_a() -> bool:
	if not can_use_skill:
		return false
	
	if defeat or is_use_skill or current_attack:
		return false
	
	if world_camera == null:
		world_camera = get_viewport().get_camera_2d()
	
	if world_camera == null:
		return false 
	
	if not is_on_floor():
		return false
	
	perform_skill_a()
	return true
