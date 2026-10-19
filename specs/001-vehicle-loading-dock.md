# 001 — Vehicle Loading Dock

**Statut :** réalisé et vérifié localement
**Source :** LLD fourni par Geoffrey dans la conversation du 19 octobre 2026 ; implémentation autonome autorisée.

## Objectif et périmètre

Automatiser la manutention des véhicules conduits par le joueur, au début/milieu de partie, sans automatiser leur déplacement. Le LLD de la conversation fait autorité.

## Critères d’acceptation

- [x] **AC1** Empreinte de placement carrée 8×8 dans les quatre orientations. Bande technique physique 1×8 au nord/est/sud/ouest ; stationnement libre 8×7 ou 7×8. Toute géométrie runtime passe par `get_vehicle_area` et les fonctions du même module.
- [x] **AC2** Détection locale toutes les 10 ticks, constante ajustable, à partir des quais enregistrés dans `storage`. Types car et spider-vehicle avec coffre compatible, y compris variantes moddées ; trains exclus. Bounding box réelle entièrement contenue, vitesse absolue strictement inférieure à 0.001.
- [x] **AC3** Aucun transfert si plusieurs véhicules compatibles sont entièrement contenus, même si certains bougent. Véhicule courant oublié dès mouvement, sortie ou invalidation.
- [x] **AC4** Inventaire standard de 100 slots (étendu par la spécification 002) accessible aux inserters depuis le bord extérieur de la bande physique ; dépôt/retrait manuel possible.
- [x] **AC5** Dix filtres de chargement et dix de déchargement indépendants, sans quantité. Interface avec deux grilles 5×2. Un item peut figurer dans les deux listes.
- [x] **AC6** Transfert instantané, déchargement avant chargement, autant que la destination accepte. Conservation des objets, de leur qualité et de leurs métadonnées, y compris inventaires pleins/limités/filtrés et transferts partiels.
- [x] **AC7** Pose, rotation, destruction/minage, sauvegarde/rechargement, plans et copie de configuration conservent une structure cohérente sans enfant orphelin ni perte silencieuse de stock.
- [x] **AC8** Le mod se charge dans Factorio 2.1, est fabricable avant les robots, possède des locales françaises/anglaises et un paquet produit par `build.sh package`.

## Hors périmètre

Quantités, débits, temporisation, vrais bras vers le véhicule, conduite automatique, trains, logistique robotique, circuits, priorités, énergie liée au transfert, files d’attente et plusieurs véhicules traités simultanément. Les bras représentés sont graphiques.

## Décisions d’implémentation

- Mod autonome `vehicle-loading-dock`, version initiale de développement 0.1.0, Factorio 2.1 uniquement. Aucune publication ni changement de version d’un mod existant.
- Entité principale pivot carrée et coffre enfant physique ; aucun inventaire de carburant, munitions ou équipement du véhicule n’est manipulé.
- Les filtres par nom acceptent toutes les qualités et préservent la qualité réelle des piles.
- Un objet présent dans les deux listes subit volontairement le déchargement puis le chargement à chaque passage.
- Les véhicules d’une autre force ne sont pas manipulés. Les quais superposés sont interdits.
- Les réglages sont sérialisés dans les tags des plans et des objets récupérés.
- Aucun dépôt Git valide n’existe au démarrage ; pas de branche ni de commit à fabriquer dans le répertoire `.git` exposé en lecture seule.

## Phases et définition de terminé

### Phase 1 — Géométrie, détection et transfert
**Couvre :** AC1, AC2, AC3, AC6.
**Impact de données :** modules sans état, configuration des quais dans storage ultérieurement.
**Vérification :** tests Lua des quatre orientations, limites, ambiguïté, vitesse, transferts partiels et conservation des piles.

### Phase 2 — Bâtiment, cycle de vie et interface
**Couvre :** AC4, AC5, AC7.
**Impact de données :** storage.docks, références aux enfants, filtres et fenêtres ouvertes.
**Vérification :** tests des événements et scénario réel Factorio pour pose, rotation, stock, GUI et rechargement.

### Phase 3 — Distribution et validation réelle
**Couvre :** AC8 et intégration des autres critères.
**Impact de données :** aucun hors sauvegarde de test temporaire.
**Vérification :** contrôles Lua/locales/paquet puis chargement et scénario automatisé dans le binaire Factorio installé, revue indépendante et corrections.

## Points ouverts

Aucun choix bloquant. L’équilibrage de recette et l’aspect graphique initial pourront être ajustés après essai en jeu.
