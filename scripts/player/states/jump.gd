extends PlayerState
## Dans les airs, en montée.


func enter(_previous: StringName) -> void:
	player.jump()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(air_speed(), delta)

	# Hauteur variable : relâcher tôt = saut plus court.
	if Input.is_action_just_released("jump"):
		player.cut_jump()

	# Sommet du saut atteint (ou tête contre un plafond).
	if player.velocity.y >= 0.0:
		go(FALL)
