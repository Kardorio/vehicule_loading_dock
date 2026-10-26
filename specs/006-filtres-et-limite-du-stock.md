# 006 — Filtres et limite du stock

**État :** réalisé et vérifié localement
**Date :** 2026-10-26

## Problème

Le joueur veut organiser et limiter le stock du quai comme celui d’un wagon : réserver des emplacements à certains objets en bleu et interdire le remplissage automatique d’une partie du stock en rouge.

## Solution

Le stock de 100 emplacements propose les filtres bleus par emplacement et la barre rouge de limitation, avec les interactions natives de Factorio. Les filtres de chargement et de déchargement restent dédiés au choix des objets transférés entre le quai et le véhicule.

Un emplacement bleu réserve une capacité à un objet ; il ne définit pas une quantité cible à maintenir. Par exemple, réserver cinq emplacements au fer et bloquer les autres limite le remplissage automatique à cinq piles de fer.

Le prototype actuel prévoit déjà une barre rouge et les transferts scriptés la respectent. L’évolution ajoute les filtres du stock et vérifie le fonctionnement conjoint des deux réglages.

## Critères d’acceptation

- [x] **AC1** Le joueur peut définir, modifier et effacer un filtre bleu sur chaque emplacement du stock depuis l’inventaire natif, comme dans un wagon.
- [x] **AC2** Les bras et le déchargement automatique du véhicule respectent les filtres des emplacements et la limite rouge. Un stock sans place admissible suspend uniquement les transferts concernés, sans perte d’objet.
- [x] **AC3** La limite rouge bloque les insertions automatiques dans les emplacements concernés sans supprimer leur contenu existant ni empêcher son extraction ; les manipulations manuelles suivent les règles natives du jeu.
- [x] **AC4** Une rotation acceptée ou refusée et une sauvegarde suivie d’un rechargement conservent le contenu, les filtres et la limite. Les quais déjà posés gardent leur contenu et leur limite existante.
- [x] **AC5** Les plans, les copier-coller, les couper-coller et le clonage conservent les filtres du stock et sa limite en plus des filtres de transfert. Les plans ne reproduisent pas le contenu du stock. Le minage restitue les objets ; une repose sans plan repart sans filtres et sans limitation, conformément au fonctionnement actuel des réglages du quai.

## Phase unique — Stock filtrable et conservation des réglages

Activer les filtres natifs sur le stock auxiliaire, préserver ses réglages lors de sa recréation, et compléter la sérialisation des plans ainsi que le clonage. Documenter les interactions entre filtres du stock et filtres de transfert.

**Couvre :** AC1, AC2, AC3, AC4, AC5.

**Impact sur les données :** filtres portés par l’inventaire natif ; ajout de la limite et des filtres du stock aux réglages enregistrés dans les plans. Les anciens plans restent utilisables sans restriction supplémentaire.

**Validation :** tests Lua pertinents et scénario dans le moteur Factorio 2.1 couvrant les insertions par bras et depuis un véhicule, le stock saturé, la rotation, les plans, le clonage et la sauvegarde suivie d’un rechargement. Vérification visuelle des filtres bleus et de la barre rouge dans l’interface native.


## Validation réalisée

- Tests Lua et lint : réussis.
- Scénario moteur dans Factorio 2.1.23 : filtres, limite, transferts, bras, rotations acceptées et refusées, sauvegarde et rechargement, export et import de plan, pose du fantôme avec son événement de construction, et clonage vérifiés.
- Migration native depuis un ancien inventaire sans filtres : contenu, qualités et limite conservés.
- Scénario du réseau logique : réussi.
- Interface native vérifiée visuellement hors écran : filtres bleus et emplacements bloqués visibles.
- Revue indépendante : correction de la conservation des filtres portant uniquement sur une qualité, puis tests Lua et moteur réussis sur la rotation, la pose depuis un plan et le clonage. Le test dédié échoue lorsque cette correction est retirée dans une copie temporaire.
- Les raccourcis clavier de copie et de coupe ne sont pas simulés ; leur chemin commun de sérialisation des plans et de construction est testé dans le moteur. Le gestionnaire de préparation de plan, événement protégé, est appelé directement avec un plan et des entités réels.
- Pas de mesure de couverture ni de hook pre-commit configuré dans le dépôt.
