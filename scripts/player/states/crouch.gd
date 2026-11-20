extends PlayerState
## Au sol, accroupi (immobile ou en déplacement).


func enter(_previous: StringName) -> void:
	player.set_crouching(true)


func exit() -> void:
	player.set_crouching(false)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(player.crouch_speed, delta)

	# Coincé sous un plafond : on reste accroupi.
	if not player.can_stand():
		return
	try_ground_transitions()
