extends PlayerState
## Au sol, sprint.


func enter(_previous: StringName) -> void:
	player.is_sprinting = true


func exit() -> void:
	player.is_sprinting = false


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(player.sprint_speed, delta)

	# Crouch pendant un sprint = glissade (sinon Crouch normal via ground_state()).
	if player.wants_slide() and not player.wants_jump():
		go(SLIDE)
		return
	try_ground_transitions()
