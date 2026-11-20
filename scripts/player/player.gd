class_name Player
extends CharacterBody2D
## Contrôleur de base pour le personnage principal d'un side-scroller.
## Gère : marche gauche/droite, sprint, saut (hauteur variable, coyote time,
## jump buffer) et crouch (hitbox réduite, impossible de se relever sous un plafond).
##
## Structure attendue :
##   Player (CharacterBody2D, origine aux pieds)
##   ├── CollisionShape2D  (RectangleShape2D)
##   └── Visual (Node2D optionnel : Sprite2D, Polygon2D, etc.)

@export_group("Déplacement")
@export var walk_speed: float = 200.0
@export var sprint_speed: float = 340.0
@export var crouch_speed: float = 90.0
@export var ground_acceleration: float = 1800.0
@export var ground_friction: float = 2000.0
@export var air_acceleration: float = 1000.0
@export var air_friction: float = 400.0

@export_group("Saut")
@export var jump_velocity: float = 430.0
## Fraction de la vitesse verticale conservée quand on relâche le saut tôt.
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.45
## Gravité plus forte en descente pour un saut moins « flottant ».
@export var fall_gravity_multiplier: float = 1.6
@export var max_fall_speed: float = 900.0
## Temps (s) pendant lequel on peut encore sauter après avoir quitté une plateforme.
@export var coyote_time: float = 0.1
## Temps (s) pendant lequel un appui sur saut est mémorisé avant de toucher le sol.
@export var jump_buffer_time: float = 0.12

@export_group("Crouch")
@export_range(0.2, 1.0) var crouch_height_ratio: float = 0.5

var facing: int = 1
var is_crouching: bool = false
var is_sprinting: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _body_shape: RectangleShape2D
var _standing_height: float
var _standing_shape_y: float

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	_ensure_input_actions()
	# Duplique la forme pour ne pas modifier une ressource partagée.
	_body_shape = _collision.shape.duplicate()
	_collision.shape = _body_shape
	_standing_height = _body_shape.size.y
	_standing_shape_y = _collision.position.y


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	_update_timers(delta)
	_update_crouch()
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal(direction, delta)
	move_and_slide()

	if direction != 0.0:
		facing = int(signf(direction))
	_update_visual()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := get_gravity().y
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and _can_stand():
		_set_crouching(false)
		velocity.y = -jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Hauteur de saut variable : relâcher tôt = saut plus court.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _handle_horizontal(direction: float, delta: float) -> void:
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and direction != 0.0

	var max_speed := walk_speed
	if is_crouching:
		max_speed = crouch_speed
	elif is_sprinting:
		max_speed = sprint_speed

	var on_floor := is_on_floor()
	var rate: float
	if direction != 0.0:
		rate = ground_acceleration if on_floor else air_acceleration
	else:
		rate = ground_friction if on_floor else air_friction

	velocity.x = move_toward(velocity.x, direction * max_speed, rate * delta)


# --- Crouch ---------------------------------------------------------------

func _update_crouch() -> void:
	if Input.is_action_pressed("crouch") and is_on_floor():
		_set_crouching(true)
	elif is_crouching and _can_stand():
		_set_crouching(false)


func _set_crouching(value: bool) -> void:
	if value == is_crouching:
		return
	is_crouching = value
	var h := _standing_height * (crouch_height_ratio if value else 1.0)
	_body_shape.size.y = h
	# Garde le bas de la hitbox aux pieds du personnage.
	_collision.position.y = _standing_shape_y + (_standing_height - h) * 0.5


## Vérifie s'il y a assez de place au-dessus pour se relever.
func _can_stand() -> bool:
	if not is_crouching:
		return true
	var shape := RectangleShape2D.new()
	# Légèrement plus petite pour ignorer le sol qu'on touche déjà.
	shape.size = Vector2(_body_shape.size.x - 2.0, _standing_height - 2.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform * Transform2D(0.0, Vector2(_collision.position.x, _standing_shape_y - 1.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


# --- Visuel ---------------------------------------------------------------

## Placeholder : retourne le visuel selon la direction et l'écrase en crouch.
## À remplacer par tes animations (AnimatedSprite2D / AnimationPlayer) plus tard.
func _update_visual() -> void:
	if _visual == null:
		return
	_visual.scale = Vector2(facing, crouch_height_ratio if is_crouching else 1.0)


# --- Inputs ---------------------------------------------------------------

## Crée les actions par défaut si elles n'existent pas déjà dans
## Projet > Paramètres du projet > Contrôles. Tu peux les redéfinir là-bas.
func _ensure_input_actions() -> void:
	var bindings := {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0), _joy_button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0), _joy_button(JOY_BUTTON_DPAD_RIGHT)],
		"jump": [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_A)],
		"crouch": [_key(KEY_S), _key(KEY_DOWN), _key(KEY_CTRL), _joy_button(JOY_BUTTON_DPAD_DOWN)],
		"sprint": [_key(KEY_SHIFT), _joy_button(JOY_BUTTON_X)],
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for event: InputEvent in bindings[action]:
			InputMap.action_add_event(action, event)


func _key(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode  # Physique : marche aussi en AZERTY (ZQSD).
	return ev


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev
