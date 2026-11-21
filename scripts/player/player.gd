class_name Player
extends CharacterBody2D
## Personnage principal d'un side-scroller.
##
## Ce script contient les réglages et les « outils » de mouvement (gravité,
## déplacement, saut, crouch). C'est la state machine (nœud StateMachine) qui
## décide lesquels utiliser selon l'état actuel : Idle, Walk, Run, Jump, Fall, Crouch, Slide,
## WallSlide, WallJump.
##
## Structure attendue :
##   Player (CharacterBody2D, origine aux pieds)
##   ├── CollisionShape2D  (RectangleShape2D)
##   ├── Visual            (Node2D optionnel : Sprite2D, Polygon2D, etc.)
##   ├── StateLabel        (Label optionnel : affiche l'état actuel, pour debug)
##   └── StateMachine      (PlayerStateMachine)
##       ├── Idle, Walk, Run, Jump, Fall, Crouch, Slide, WallSlide, WallJump  (PlayerState)

@export_group("Capacités")
## Peut se déplacer à gauche/droite. Désactivé : le personnage freine et reste sur place.
@export var can_move: bool = true
@export var can_sprint: bool = true
@export var can_jump: bool = true
@export var can_crouch: bool = true
## Glissade (crouch pendant un sprint). Verrouillée au départ : se débloque
## en cours de partie avec unlock_slide(). Coche-la ici pour tester.
@export var slide_unlocked: bool = false
## Glissade permise en ce moment (ex. : désactivée sur certains types de sol,
## zones, cinématiques). Ne sert que si slide_unlocked est vrai.
@export var can_slide: bool = true
## Wall slide (glisser contre un mur en poussant vers lui). Dispo dès le départ.
## Désactivé : pas de wall slide (ex. : murs glissants, zones).
@export var can_wall_slide: bool = true
## Wall-jump (sauter depuis un mur). Verrouillé au départ : se débloque en cours de
## partie avec unlock_wall_jump(). Coche-le ici pour tester. Le wall slide n'en dépend pas.
@export var wall_jump_unlocked: bool = false
## Wall-jump permis en ce moment (ex. : désactivé sur certains murs, zones,
## cinématiques). Ne sert que si wall_jump_unlocked est vrai.
@export var can_wall_jump: bool = true

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

@export_group("Slide")
## Vitesse au début de la glissade (la vitesse actuelle est gardée si elle est plus grande).
@export var slide_speed: float = 480.0
## Durée max (s) de la glissade.
@export var slide_duration: float = 0.45
## Ralentissement pendant la glissade (pixels/s²).
@export var slide_friction: float = 600.0
## Temps (s) avant de pouvoir glisser à nouveau.
@export var slide_cooldown: float = 0.3
## Vitesse horizontale ajoutée quand on saute pendant une glissade (saute plus loin).
@export var slide_jump_boost: float = 50.0

@export_group("Wall jump")
## Vitesse de chute max au début du wall slide (collé au mur en poussant vers lui).
@export var wall_slide_speed: float = 120.0
## Temps (s) sur le mur avant que la glissade commence à accélérer.
@export var wall_slide_accel_delay: float = 0.3
## Vitesse de chute max atteinte quand la glissade accélère.
@export var wall_slide_fast_speed: float = 350.0
## Durée (s) de la transition de wall_slide_speed vers wall_slide_fast_speed.
## Courbe en S : démarre doucement, accélère, puis se stabilise en douceur.
@export var wall_slide_ramp_time: float = 0.5
## Temps total (s) sur le mur avant de lâcher prise et tomber. Plus de prise ni de
## wall-jump sur ce mur avant d'avoir touché le sol ou l'autre mur.
@export var wall_slide_max_time: float = 1.0
## Poussée horizontale à l'opposé du mur.
@export var wall_jump_push: float = 320.0
## Vitesse verticale du wall-jump.
@export var wall_jump_velocity: float = 420.0
## Temps (s) pendant lequel la direction est bloquée après un wall-jump
## (empêche de revenir sur le même mur).
@export var wall_jump_lock_time: float = 0.2
## Temps (s) pendant lequel on peut encore wall-jumper après avoir quitté un mur.
@export var wall_coyote_time: float = 0.08
## Distance (px) à laquelle un mur est détecté.
@export var wall_check_distance: float = 2.0

var facing: int = 1
var is_crouching: bool = false
var is_sprinting: bool = false
var is_sliding: bool = false
## Vitesse max dans les airs gagnée par un saut depuis une glissade.
## Remise à 0 à l'atterrissage ou si on change de direction.
var air_momentum: float = 0.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _slide_cooldown_timer: float = 0.0
var _wall_coyote_timer: float = 0.0
## Côté du dernier mur touché : -1 = gauche, 1 = droite.
var _last_wall_side: int = 0
## Temps passé à glisser sur le mur actuel (gardé si on lâche puis reprend le même mur).
var wall_slide_time: float = 0.0
var _wall_slide_side: int = 0
## Côté du mur dont on a lâché prise (0 = aucun). Remis à 0 au sol.
var _tired_wall_side: int = 0
var _body_shape: RectangleShape2D
var _standing_height: float
var _standing_shape_y: float

@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Node2D = get_node_or_null("Visual")
@onready var _state_label: Label = get_node_or_null("StateLabel")


func _ready() -> void:
	_ensure_input_actions()
	# Duplique la forme pour ne pas modifier une ressource partagée.
	_body_shape = _collision.shape.duplicate()
	_collision.shape = _body_shape
	_standing_height = _body_shape.size.y
	_standing_shape_y = _collision.position.y

	state_machine.state_changed.connect(_on_state_changed)
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	state_machine.physics_update(delta)
	move_and_slide()

	var direction := get_input_direction()
	# Pendant une glissade, la direction est verrouillée.
	if direction != 0.0 and not is_sliding:
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

	if not is_sliding:
		_slide_cooldown_timer -= delta

	if is_on_floor():
		_reset_wall_grip()

	var wall := get_wall_side()
	if wall != 0:
		_last_wall_side = wall
		_wall_coyote_timer = wall_coyote_time
	else:
		_wall_coyote_timer -= delta


func _on_state_changed(_from: StringName, to: StringName) -> void:
	if _state_label:
		_state_label.text = String(to)


# --- Lecture des inputs (utilisée par les états) --------------------------

func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right") if can_move else 0.0


func wants_sprint() -> bool:
	return can_sprint and get_input_direction() != 0.0 and Input.is_action_pressed("sprint")


func wants_crouch() -> bool:
	return can_crouch and Input.is_action_pressed("crouch")


## Vrai si on vient d'appuyer sur crouch, au sol, et que le cooldown est terminé.
## (Vérifié seulement depuis l'état Run.)
func wants_slide() -> bool:
	return slide_unlocked and can_slide and is_on_floor() and _slide_cooldown_timer <= 0.0 and Input.is_action_just_pressed("crouch")


func can_use_wall_jump() -> bool:
	return wall_jump_unlocked and can_wall_jump


## Vrai si on est dans les airs, en chute, collé à un mur ET qu'on pousse vers lui.
## Ne dépend pas du wall-jump : on peut wall slider sans pouvoir wall-jumper.
func wants_wall_slide() -> bool:
	if not can_wall_slide or velocity.y < 0.0:
		return false
	var wall := get_wall_side()
	return wall != 0 and wall != _tired_wall_side and signf(get_input_direction()) == wall


## Vrai si on a appuyé sur saut récemment ET qu'on touche un mur
## (ou qu'on vient de le quitter : wall_coyote_time), sauf si on a lâché prise sur ce mur.
func wants_wall_jump() -> bool:
	if not can_use_wall_jump() or is_on_floor() or _last_wall_side == _tired_wall_side:
		return false
	return _jump_buffer_timer > 0.0 and _wall_coyote_timer > 0.0


## Vrai si on a appuyé sur saut récemment ET qu'on peut sauter
## (au sol ou dans le coyote time, avec la place pour se relever).
func wants_jump() -> bool:
	return can_jump and _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and can_stand()


# --- Actions (utilisées par les états) ------------------------------------

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := get_gravity().y
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


## Accélère vers la direction des inputs (ou freine si aucune), jusqu'à max_speed.
func move_horizontal(max_speed: float, delta: float) -> void:
	var direction := get_input_direction()
	var on_floor := is_on_floor()
	var rate: float
	if direction != 0.0:
		rate = ground_acceleration if on_floor else air_acceleration
	else:
		rate = ground_friction if on_floor else air_friction
	velocity.x = move_toward(velocity.x, direction * max_speed, rate * delta)


func jump() -> void:
	set_crouching(false)
	velocity.y = -jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


## Coupe le saut quand on relâche le bouton pendant la montée.
func cut_jump() -> void:
	if velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func set_crouching(value: bool) -> void:
	if value == is_crouching:
		return
	is_crouching = value
	var h := _standing_height * (crouch_height_ratio if value else 1.0)
	_body_shape.size.y = h
	# Garde le bas de la hitbox aux pieds du personnage.
	_collision.position.y = _standing_shape_y + (_standing_height - h) * 0.5


func start_slide() -> void:
	is_sliding = true
	set_crouching(true)


## Côté du mur touché dans les airs : -1 = gauche, 1 = droite, 0 = aucun.
## Si les deux côtés touchent, celui vers lequel on pousse est prioritaire.
func get_wall_side() -> int:
	if is_on_floor():
		return 0
	var preferred := int(signf(get_input_direction()))
	if preferred == 0:
		preferred = facing
	for side: int in [preferred, -preferred]:
		if test_move(global_transform, Vector2(side * wall_check_distance, 0.0)):
			return side
	return 0


## Appelé en entrant dans WallSlide : le compteur repart à 0 seulement si c'est
## un autre mur (sinon lâcher puis reprendre le même mur ne remet pas le temps à 0).
func start_wall_slide() -> void:
	var wall := get_wall_side()
	if wall != _wall_slide_side:
		wall_slide_time = 0.0
		_wall_slide_side = wall
	if wall != _tired_wall_side:
		_tired_wall_side = 0  # Nouveau mur : on retrouve sa prise.


## Lâche prise : on tombe, plus de wall slide ni de wall-jump sur ce mur.
func lose_wall_grip() -> void:
	_tired_wall_side = _wall_slide_side
	_wall_coyote_timer = 0.0


func _reset_wall_grip() -> void:
	wall_slide_time = 0.0
	_wall_slide_side = 0
	_tired_wall_side = 0


## Saut depuis un mur : poussée à l'opposé du dernier mur touché.
func wall_jump() -> void:
	set_crouching(false)
	var away := -_last_wall_side
	velocity = Vector2(away * wall_jump_push, -wall_jump_velocity)
	facing = away
	# L'élan est gardé dans les airs (comme un saut depuis une glissade).
	air_momentum = wall_jump_push
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_coyote_timer = 0.0
	_reset_wall_grip()


## Débloque le wall-jump (à appeler depuis un objet, un événement, etc.).
func unlock_wall_jump() -> void:
	wall_jump_unlocked = true


## Débloque la glissade (à appeler depuis un objet, un événement, etc.).
func unlock_slide() -> void:
	slide_unlocked = true


## Saut depuis une glissade : bonus de vitesse, conservé jusqu'à l'atterrissage.
func apply_slide_jump_boost() -> void:
	velocity.x = facing * (absf(velocity.x) + slide_jump_boost)
	air_momentum = absf(velocity.x)


func end_slide() -> void:
	is_sliding = false
	set_crouching(false)
	_slide_cooldown_timer = slide_cooldown


## Vérifie s'il y a assez de place au-dessus pour se relever.
func can_stand() -> bool:
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
## À remplacer par tes animations plus tard (state_machine.get_current_state_name()
## donne l'animation à jouer : "Idle", "Walk", "Run", "Jump", "Fall", "Crouch", "Slide",
## "WallSlide", "WallJump").
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
