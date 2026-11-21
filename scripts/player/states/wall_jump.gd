extends PlayerState
## Dans les airs, saut depuis un mur : poussée à l'opposé du mur.
## La direction est bloquée un court instant (wall_jump_lock_time) : impossible de
## revenir sur le même mur, il faut alterner entre deux murs pour monter.

var _lock_timer: float = 0.0


func enter(_previous: StringName) -> void:
	_wall_jump()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if _lock_timer > 0.0:
		_lock_timer -= delta  # Direction bloquée : on garde la poussée.
	else:
		player.move_horizontal(air_speed(), delta)

	# Hauteur variable : relâcher tôt = saut plus court.
	if Input.is_action_just_released("jump"):
		player.cut_jump()

	# Mur d'en face touché : on peut enchaîner directement (couloirs).
	if player.wants_wall_jump():
		_wall_jump()
	# Sommet du saut atteint (ou tête contre un plafond).
	elif player.velocity.y >= 0.0:
		go(FALL)


func _wall_jump() -> void:
	player.wall_jump()
	_lock_timer = player.wall_jump_lock_time
