extends PlayerState
## Au sol, glissade : déclenchée en appuyant sur crouch pendant un sprint (Run).
## Hitbox accroupie, élan vers l'avant qui ralentit. Direction verrouillée,
## mais on peut sauter pour annuler la glissade : saut plus long (slide_jump_boost).

var _timer: float = 0.0


func enter(_previous: StringName) -> void:
	player.start_slide()
	_timer = player.slide_duration
	# Garde la vitesse actuelle si elle est déjà plus grande que slide_speed.
	player.velocity.x = player.facing * maxf(absf(player.velocity.x), player.slide_speed)


func exit() -> void:
	player.end_slide()


func physics_update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.slide_friction * delta)

	var stuck := not player.can_stand()  # Plafond bas : impossible de se relever.

	if player.wants_jump():  # wants_jump() vérifie déjà can_stand().
		player.apply_slide_jump_boost()
		go(JUMP)
	elif not player.is_on_floor():
		if not stuck:
			go(FALL)
	elif _timer <= 0.0 or absf(player.velocity.x) <= player.crouch_speed:
		# Fin de la glissade. Sous un plafond, Crouch garde le joueur accroupi.
		go(CROUCH if stuck else ground_state())
