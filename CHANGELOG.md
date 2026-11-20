# Journal des changements — Insomnia

Toutes les modifications notables du projet sont notées ici, de la plus récente à la plus ancienne.

Catégories utilisées : **Ajouté**, **Modifié**, **Corrigé**, **Retiré**.

---

## [Non commité] · branche `base-player-movement`

### Ajouté
- **Slide** : appuyer sur crouch pendant un sprint (état `Run`) déclenche une glissade.
  - Nouvel état `Slide` (`scripts/player/states/slide.gd`, nœud `Slide` sous `StateMachine`).
  - Hitbox accroupie, élan vers l'avant (`slide_speed`, ou la vitesse actuelle si plus grande) qui ralentit (`slide_friction`).
  - Direction verrouillée pendant la glissade.
  - **Saut depuis une glissade** : on saute plus loin. Bonus de vitesse `slide_jump_boost` (50), et l'élan est conservé dans les airs jusqu'à l'atterrissage (`air_momentum`). Changer de direction en l'air annule l'élan.
  - Fin après `slide_duration` ou quand la vitesse tombe sous `crouch_speed` → `Crouch` si crouch est toujours tenu (ou sous un plafond), sinon l'état au sol normal.
  - Cooldown (`slide_cooldown`) avant de pouvoir glisser à nouveau.
- `slide_unlocked` (groupe Capacités) : **désactivé par défaut**, la glissade se débloque en cours de partie avec `unlock_slide()`. À cocher dans l'inspecteur pour tester.
- `can_slide` (groupe Capacités, activé par défaut) : glissade permise ou non **en ce moment** (ex. : certains types de sol, zones). Il faut `slide_unlocked` **et** `can_slide` pour glisser.
- Réglages dans l'inspecteur : groupe **Slide** (`slide_speed`, `slide_duration`, `slide_friction`, `slide_cooldown`, `slide_jump_boost`).
- Fichiers `.gd.uid` générés par Godot pour les scripts de la state machine et des états.

### Modifié
- `Run` : vérifie la glissade avant les transitions au sol.
- `air_speed()` (utilisé par `Jump` et `Fall`) tient compte de l'élan d'un saut depuis une glissade ; `Fall` le remet à 0 à l'atterrissage.
- `player.tscn` : UID ajoutés par Godot sur les scripts et nœuds ; valeurs du slide ajustées dans l'inspecteur (`slide_speed` 440, `slide_duration` 0.65, `slide_friction` 400).
- `project.godot` : action `crouch` définie dans les Contrôles du projet → **Alt**, **Flèche bas**, **Croix directionnelle bas** (manette).

---

## 2026-11-20 · commit `edd401f` · branche `player-state-machine`

### Ajouté
- **State machine du joueur** (nœud `StateMachine` dans `player.tscn`), avec 6 états :

  | État | Quand |
  |---|---|
  | `Idle` | Au sol, immobile |
  | `Walk` | Au sol, en déplacement |
  | `Run` | Au sol, en déplacement avec sprint |
  | `Jump` | Dans les airs, en montée |
  | `Fall` | Dans les airs, en chute (coyote time et jump buffer gérés ici) |
  | `Crouch` | Au sol, accroupi (immobile ou en déplacement) ; reste accroupi sous un plafond |

- `scripts/player/state_machine/player_state_machine.gd` : change d'état (`transition_to()`), signal `state_changed(from, to)`, `get_current_state_name()`.
- `scripts/player/state_machine/player_state.gd` : classe de base des états (`enter`, `exit`, `physics_update`) + helpers partagés.
- `scripts/player/states/` : un script par état.
- `StateLabel` au-dessus du joueur qui affiche l'état actuel (debug, peut être supprimé).

### Modifié
- `player.gd` réorganisé : il garde les réglages et les « outils » (`apply_gravity`, `move_horizontal`, `jump`, `cut_jump`, `set_crouching`, `can_stand`, `wants_jump`…), et c'est l'état actif qui décide quoi utiliser. Comportement du mouvement inchangé.

---

## 2026-11-20 · commit `22c4221` · branche `workflow-readme`

### Ajouté
- `README.md` : section **Workflow** (branche par feature → push sur une branche GitHub du même nom → PR → merge manuel).

---

## 2026-11-20 · commit `120073b` · branche `base-player-movement`

### Ajouté
- **Player — groupe « Capacités »** dans l'inspecteur pour activer/désactiver des fonctionnalités :
  - `can_move` : désactivé → gauche/droite ignorés, le perso freine (la gravité reste active).
  - `can_sprint` : désactivé → toujours à la vitesse de marche.
  - `can_jump` : désactivé → plus de saut.
  - `can_crouch` : désactivé → plus de crouch (se relève dès qu'il y a la place).
  - Modifiables aussi en jeu par code, ex. `player.can_move = false` pendant une cinématique.
- `CHANGELOG.md` (ce fichier).

### Modifié
- `scenes/player/player.tscn` : identifiants (UID) ajoutés automatiquement par Godot à l'ouverture, sans changement de comportement.

---

## 2026-11-20 · commit `0abf573` · branche `base-player-movement`

### Ajouté
- **Dépôt Git** initialisé, remote `origin` → `git@github.com:Pbrochu94/Insomnia.git`.
- **`scripts/player/player.gd`** — contrôleur de mouvement (CharacterBody2D) :
  - **Gauche / droite** avec accélération et friction (contrôle réduit dans les airs).
  - **Sprint** : 200 → 340 de vitesse (impossible en crouch).
  - **Saut** : hauteur variable (relâcher tôt = plus court), chute plus rapide, *coyote time* et *jump buffer*.
  - **Crouch** : hitbox réduite de moitié, vitesse 90, impossible de se relever ou sauter sous un plafond bas.
  - Contrôles créés automatiquement s'ils n'existent pas (clavier par position physique → ZQSD en AZERTY, + manette) :

    | Action | Clavier | Manette |
    |---|---|---|
    | Gauche / droite | A/D, flèches | Stick gauche, D-pad |
    | Saut | Espace, W, ↑ | A |
    | Crouch | S, ↓, Ctrl | D-pad ↓ |
    | Sprint | Shift | X |

  - Toutes les valeurs réglables dans l'inspecteur (groupes Déplacement, Saut, Crouch).
  - Visuel temporaire dans `_update_visual()` (rectangle retourné selon la direction, écrasé en crouch) — à remplacer par les animations.
- **`scenes/player/player.tscn`** — hitbox 24×48, rectangle bleu temporaire, caméra qui suit.
- **`scenes/levels/test_level.tscn`** — sol, plateforme (test du saut) et plafond bas (test du crouch). Lancer avec F6.
