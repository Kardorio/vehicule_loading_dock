# 002 — Électricité, stock et voyant

**Statut :** réalisé et vérifié localement
**Source :** retours de Geoffrey après essai en jeu, implémentation autonome poursuivie.

## Comportement attendu

- **AC1** Le quai nécessite un réseau électrique alimenté ; aucun transfert sans alimentation suffisante. Consommation fixe de 30 kW, indépendante de la quantité transférée. L’interface indique l’absence d’alimentation.
- **AC2** Le stock passe à exactement 100 emplacements, toutes qualités du bâtiment confondues. Les quais déjà posés conservent contenu, filtres et limite manuelle. Une limite anciennement sans restriction s’étend automatiquement aux 100 emplacements.
- **AC3** Un voyant fixé à la bande technique est orange lorsque le quai alimenté attend un véhicule valide, vert lorsqu’un seul véhicule compatible est entièrement stationné et arrêté, éteint sans alimentation. La couleur confirme la détection même sans filtre ou lorsque les inventaires sont pleins.
- **AC4** Le voyant suit les quatre rotations, résiste aux sauvegardes/rechargements et au clonage, et disparaît au retrait du quai. Les graphismes et les collisions restent cohérents avec l’empreinte initiale.
- **AC5** Tests Lua, tests moteur (coupure/reprise et migration incluses), inspection du voyant dans un rendu réel, archive et lien local prêts pour le prochain essai.

- **AC6** Vignette `thumbnail.png` incluse au paquet, présentation française pour le portail et galerie de captures réelles prêtes, sans publication.

## Réalisation

### Phase 1 — Alimentation, capacité et état visuel
**Couvre :** AC1, AC2, AC3, AC4.
**Données :** état des rendus et capacité connue dans chaque entrée de storage.docks. Migration paresseuse au premier passage runtime pour fonctionner même sans changement de version de développement.
**Vérification :** tests unitaires des états et de la migration ; scénario dans Factorio 2.1.

### Phase 2 — Validation et livraison locale
**Couvre :** AC5, AC6.
**Données :** aucune autre migration.
**Vérification :** scénario moteur, capture graphique, revue indépendante, ./build.sh package et ./build.sh devlink.

## Décisions

30 kW est une valeur initiale ajustable. Le voyant est orange si le véhicule bouge, dépasse ou si plusieurs véhicules sont présents. Sans courant, il est sombre. La version reste celle du développement local non publié ; aucune release ni entrée de changelog n’est créée.

## Résultats de validation

Tests Lua et locales réussis. Scénario moteur Factorio 2.1.21 : électricité native, coupure/reprise, états du voyant, inventaires et clonage validés. Migration réelle d’un prototype à 50 emplacements vers 100 à version de développement identique : contenu, tags, qualités, filtres et limites préservés. Rendu réel hors écran inspecté : orange sans véhicule, vert avec véhicule, interface à 100 emplacements.

Revue indépendante des sources électriques, de migration et du voyant : aucun défaut restant identifié. Vignette et documentation de portail préparées, aucune publication effectuée.
