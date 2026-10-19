# 003 — Résumé latéral des stocks

**Statut :** réalisé et vérifié localement
**Source :** demande de Geoffrey, poursuite de l’implémentation autonome.

## Comportement attendu

- **AC1** Un panneau latéral s’ouvre automatiquement lorsqu’un joueur occupe ou pilote à distance un véhicule compatible entièrement contenu dans la zone d’un quai de sa force. Un véhicule seulement sélectionné n’ouvre pas de panneau. Le véhicule actif est celui du contrôleur courant, jamais le véhicule physique d’un personnage resté ailleurs.
- **AC2** Le panneau présente séparément le coffre du véhicule et le stock du quai : objets, quantités regroupées par objet et qualité, et nombre d’emplacements occupés/total. Il est strictement en lecture seule et n’ouvre aucune fenêtre native ni ne prend le contrôle des entrées du joueur.
- **AC3** Le contenu est actualisé après les transferts périodiques, au maximum toutes les dix ticks. Les inventaires vides sont explicites ; les longues listes défilent sans sortir de l’écran.
- **AC4** Le panneau se ferme immédiatement lors de la descente du véhicule ou de l’abandon du contrôle distant ; au plus au tick suivant pour la sortie géométrique, la destruction/invalidation du véhicule ou du quai, le changement de force/surface ou la déconnexion. Une voiture laissée sur le quai ne maintient pas le panneau d’un joueur descendu.
- **AC5** Plusieurs joueurs ont des panneaux indépendants. La sauvegarde/reprise, l’entrée dans un autre véhicule et la disparition d’éléments d’interface ne laissent aucun panneau périmé. Aucun inventaire d’une force étrangère n’est révélé.
- **AC6** Tests Lua des états et quantités, scénario graphique avec un vrai conducteur et contrôle distant, revue, documentation portail et archive/lien local actualisés.

## Décisions

Le panneau est latéral et non modal. Sa présence dépend du véhicule actif et de sa contenance géométrique dans le quai, pas de l’électricité ou de l’arrêt : il reste consultable pendant une coupure ou pendant une manœuvre à l’intérieur de la zone. Les règles de transfert du quai restent inchangées. La fermeture est contrôlée chaque tick uniquement pour les panneaux ouverts ; les inventaires sont relus toutes les dix ticks et l’affichage n’est reconstruit que si le contenu change.

## Phases

### Phase 1 — Présentation et suivi de la session de conduite
**Couvre :** AC1, AC2, AC3, AC4, AC5.
**Données :** storage.vehicle_summaries, une entrée par joueur, références au véhicule actif et identifiant du quai ; aucune migration d’inventaire.
**Vérification :** tests de regroupement/qualité, contrôleurs, ouverture/fermeture, isolation des joueurs et récupération d’un panneau détruit.

### Phase 2 — Vérification réelle et livraison locale
**Couvre :** AC6.
**Données :** aucune autre évolution.
**Vérification :** tests moteur existants, scénario graphique conducteur/commande distante, revue et ./build.sh package puis ./build.sh devlink.

## Vérifications

Tests Lua réussis pour regroupement, qualité, états de contrôle, fermeture, isolation des joueurs et récupération d’un panneau supprimé. Scénario graphique Factorio 2.1.21 réussi avec un vrai conducteur et un vrai tank piloté à distance, le personnage restant dans une autre voiture. Les événements natifs ferment immédiatement le panneau à la descente et à la libération du tank ; la validation du tick de production le ferme au tick suivant hors zone. Contrôle de l’actualisation en dix ticks et absence de fenêtre native ouverte. Capture française inspectée et ajoutée à la galerie du portail.

Revue indépendante : aucun défaut restant. Correction complémentaire de la phrase sous les filtres : explication complète avec retour à la ligne automatique, dans les deux langues.
