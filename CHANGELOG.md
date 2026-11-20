# Journal des changements — Insomnia

Toutes les modifications notables du projet sont notées ici, de la plus récente à la plus ancienne.

Catégories utilisées : **Ajouté**, **Modifié**, **Corrigé**, **Retiré**.

---

## 2026-11-20 · commit « Add workflow section to README » · branche `workflow-readme`

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
