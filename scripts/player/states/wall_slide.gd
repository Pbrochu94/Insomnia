extends PlayerState
## Dans les airs, collé à un mur en poussant vers lui : la chute est ralentie.
## Après wall_slide_accel_delay, la glissade accélère en douceur (courbe en S sur
## wall_slide_ramp_time) ; après wall_slide_max_time, le joueur lâche prise et
## tombe. Sauter = wall-jump (si débloqué). Lâcher la direction = chute.


func enter(_previous: StringName) -> void:
	player.air_momentum = 0.0
	player.start_wall_slide()


func physics_update(delta: float) -> void:
	player.wall_slide_time += delta
	player.apply_gravity(delta)
	player.velocity.y = minf(player.velocity.y, _max_fall_speed())
	player.move_horizontal(air_speed(), delta)  # On pousse vers le mur : reste collé.

	if player.wants_wall_jump():
		go(WALL_JUMP)
	elif player.is_on_floor():
		go(ground_state())
	elif player.wall_slide_time >= player.wall_slide_max_time:
		player.lose_wall_grip()
		go(FALL)
	elif not player.wants_wall_slide():
		go(FALL)


## Vitesse de chute max selon le temps passé sur le mur :
## lente, puis transition en S vers la vitesse rapide.
func _max_fall_speed() -> float:
	var t := (player.wall_slide_time - player.wall_slide_accel_delay) / maxf(player.wall_slide_ramp_time, 0.001)
	var weight := smoothstep(0.0, 1.0, t)
	return lerpf(player.wall_slide_speed, player.wall_slide_fast_speed, weight)
