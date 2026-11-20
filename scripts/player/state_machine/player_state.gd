class_name PlayerState
extends Node
## Classe de base de tous les états du joueur.
## Pour créer un nouvel état : un script qui `extends PlayerState`, un nœud enfant
## de StateMachine avec ce script, et une constante de nom ci-dessous.

# Noms des états (= noms des nœuds sous StateMachine).
const IDLE := &"Idle"
const WALK := &"Walk"
const RUN := &"Run"
const JUMP := &"Jump"
const FALL := &"Fall"
const CROUCH := &"Crouch"
const SLIDE := &"Slide"

var player: Player
var state_machine: PlayerStateMachine


## Appelé en entrant dans l'état.
func enter(_previous: StringName) -> void:
	pass


## Appelé en sortant de l'état.
func exit() -> void:
	pass


## Appelé à chaque frame physique tant que l'état est actif.
func physics_update(_delta: float) -> void:
	pass


# --- Helpers partagés -----------------------------------------------------

## Change d'état. Retourne true pour pouvoir écrire `return go(X)`.
func go(state_name: StringName) -> bool:
	state_machine.transition_to(state_name)
	return true


## L'état au sol qui correspond aux inputs actuels.
func ground_state() -> StringName:
	if player.wants_crouch():
		return CROUCH
	if player.get_input_direction() == 0.0:
		return IDLE
	return RUN if player.wants_sprint() else WALK


## Transitions communes aux états au sol (Idle, Walk, Run, Crouch).
## Retourne true si on a changé d'état.
func try_ground_transitions() -> bool:
	if not player.is_on_floor():
		return go(FALL)
	if player.wants_jump():
		return go(JUMP)
	var next := ground_state()
	if next != name:
		return go(next)
	return false


## Vitesse max dans les airs : on garde le sprint si Shift est tenu,
## et l'élan d'un saut depuis une glissade tant qu'on va dans la même direction.
func air_speed() -> float:
	var speed := player.sprint_speed if player.wants_sprint() else player.walk_speed
	if player.air_momentum > 0.0:
		var direction := player.get_input_direction()
		if direction != 0.0 and signf(direction) != signf(player.velocity.x):
			player.air_momentum = 0.0  # Changement de direction : on perd l'élan.
		else:
			speed = maxf(speed, player.air_momentum)
	return speed
