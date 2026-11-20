extends PlayerState
## Dans les airs, en chute.


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(air_speed(), delta)

	# Coyote time / jump buffer : wants_jump() gère les deux.
	if player.wants_jump():
		go(JUMP)
	elif player.is_on_floor():
		player.air_momentum = 0.0
		go(ground_state())
