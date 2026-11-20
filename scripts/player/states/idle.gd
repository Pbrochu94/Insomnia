extends PlayerState
## Au sol, immobile.


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(player.walk_speed, delta)
	try_ground_transitions()
