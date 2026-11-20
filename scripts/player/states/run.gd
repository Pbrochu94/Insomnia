extends PlayerState
## Au sol, sprint.


func enter(_previous: StringName) -> void:
	player.is_sprinting = true


func exit() -> void:
	player.is_sprinting = false


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontal(player.sprint_speed, delta)
	try_ground_transitions()
