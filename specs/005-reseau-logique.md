# 005 — Lecture du quai par réseau logique

**État :** réalisé et vérifié localement
**Date :** 2026-10-20

## Problème

Le joueur ne peut pas utiliser le stock du quai ni la présence d’un véhicule dans ses automatismes à câbles rouges ou verts.

## Solution

Un câble rouge ou vert se branche directement sur le quai. Chaque réseau reçoit les quantités du stock du quai, regroupées par objet et qualité, et un signal virtuel « Véhicule stationné » valant 1 pour un seul véhicule compatible entièrement dans la zone et arrêté. Une valeur nulle est représentée par l’absence du signal, comme pour les autres signaux Factorio.

La lecture fonctionne aussi sans électricité ; seuls les transferts restent soumis à l’alimentation existante. Le contenu du coffre du véhicule n’est pas additionné au stock du quai. Les signaux entrants ne pilotent pas le quai.

## Critères d’acceptation

- [x] **AC1** Les câbles rouges et verts se branchent au quai dans les quatre orientations, sans mélanger les deux réseaux.
- [x] **AC2** Chaque réseau reçoit les quantités exactes du stock, qualités distinctes, après les transferts et modifications manuelles, y compris pour un stock vide.
- [x] **AC3** Le signal « Véhicule stationné » vaut 1 pour un véhicule arrêté et entièrement contenu ; il est absent sans véhicule, en mouvement, à cheval sur la limite ou avec plusieurs véhicules admissibles.
- [x] **AC4** La lecture du stock et la détection restent disponibles sans courant ; les transferts restent suspendus.
- [x] **AC5** Rotation, rechargement, quais déjà posés, clonage et suppression ne laissent ni signaux périmés ni entités auxiliaires orphelines ; les branchements du quai survivent à la rotation.

## Phase unique — Connexion, émission et validation

Ajouter le connecteur au bâtiment principal, publier le stock et le signal de présence, intégrer leur cycle de vie et documenter l’utilisation.

**Couvre :** AC1, AC2, AC3, AC4, AC5.

**Impact sur les données :** référence vers un émetteur interne dans l’état de chaque quai, créé automatiquement pour les quais existants.

**Validation :** tests Lua et scénario dans le moteur Factorio, avec lecture des deux réseaux, rotation, coupure de courant, rechargement et suppression.

## Validation réalisée

- `./build.sh lint` et `./build.sh test` : réussis.
- `python3 tests/smoke.py` : scénario existant réussi dans Factorio 2.1.21.
- `python3 tests/circuit.py` : critères ci-dessus vérifiés dans Factorio 2.1.21, notamment après sauvegarde et rechargement, réparation d’un quai sans émetteur, transfert alimenté, rotation, clonage, minage et destruction.
- Pas de mesure de couverture ni de hook pre-commit configuré dans le dépôt.

## Suivi

Aucun point fonctionnel différé.
