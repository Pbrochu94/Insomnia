class_name PlayerStateMachine
extends Node
## Gère l'état actuel du joueur et les transitions entre états.
## Chaque enfant (qui hérite de PlayerState) est un état, identifié par son nom de nœud.

signal state_changed(from: StringName, to: StringName)

## État au démarrage. Si vide, le premier enfant est utilisé.
@export var initial_state: PlayerState

var current_state: PlayerState
var _states: Dictionary[StringName, PlayerState] = {}


## Appelé par le Player dans son _ready(), une fois qu'il est prêt.
func init(player: Player) -> void:
	for child in get_children():
		if child is PlayerState:
			child.player = player
			child.state_machine = self
			_states[child.name] = child

	if _states.is_empty():
		push_error("PlayerStateMachine : aucun état enfant trouvé.")
		return
	if initial_state == null:
		initial_state = _states.values()[0]

	current_state = initial_state
	current_state.enter(&"")
	state_changed.emit(&"", current_state.name)


func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func transition_to(state_name: StringName) -> void:
	var next: PlayerState = _states.get(state_name)
	if next == null:
		push_error("PlayerStateMachine : l'état '%s' n'existe pas." % state_name)
		return
	if next == current_state:
		return

	var previous := current_state
	previous.exit()
	current_state = next
	next.enter(previous.name)
	state_changed.emit(previous.name, next.name)


func get_current_state_name() -> StringName:
	return current_state.name if current_state else &""
