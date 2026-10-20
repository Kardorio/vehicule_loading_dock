# Vehicle Loading Dock

Mod pour **Factorio 2.1**. Le joueur conduit son véhicule ; le quai automatise le chargement et le déchargement de son coffre lorsqu’il est entièrement stationné et arrêté.

## Utilisation

1. Rechercher l’automobile, puis fabriquer le quai dans la catégorie transport.
2. Poser le bâtiment de 8×8 cases. La bande technique occupe un bord de 1×8 ; les autres cases constituent le stationnement.
3. Alimenter le quai avec un réseau électrique (consommation fixe de 30 kW), puis ouvrir le quai pour accéder au stock de 100 emplacements et aux deux grilles de filtres.
4. Choisir jusqu’à dix types d’objets à charger et dix à décharger. Aucune quantité n’est définie ; toutes les qualités sont acceptées et conservées.
5. Alimenter ou vider le stock avec des bras classiques placés le long du bord extérieur de la bande technique, ou à la main.
6. Garer un seul véhicule complètement dans la zone libre, puis s’arrêter. Le quai décharge avant de charger, autant que les inventaires le permettent.

Les voitures, chars et spidertrons sont compatibles, ainsi que les véhicules de mods utilisant les types `car` et `spider-vehicle` avec un coffre. Seul le coffre est manipulé : ni carburant, ni munitions, ni grille d’équipement. Le véhicule doit appartenir à la force du quai.

La détection est locale et s’effectue toutes les dix ticks. La bounding box entière doit tenir dans le stationnement, sans alignement contre les bras. Si plusieurs véhicules compatibles y sont entièrement contenus, les transferts sont suspendus. Un objet présent dans les deux listes est déchargé, puis rechargé.

La rotation conserve l’empreinte carrée et le stock. Elle est refusée si la nouvelle bande technique est occupée. Le minage récupère le stock, mais les filtres sont vides lors de la repose. Les plans mémorisent les filtres ; la copie directe des réglages entre quais n’est pas prise en charge. En cas de destruction, le stock restant est déposé au sol.

## Réseau logique

Branchez un câble rouge ou vert directement sur le quai. Les deux réseaux reçoivent le contenu du **stock du quai**, avec un signal par objet et qualité, ainsi que le signal virtuel **Véhicule stationné** (icône de voiture, identifiant `vld-vehicle-present`). Ce signal vaut **1** lorsqu’un seul véhicule compatible est entièrement dans la zone et arrêté ; il est absent dans les autres cas.

La lecture fonctionne même sans électricité. Les transferts restent soumis à l’alimentation du quai. Le coffre du véhicule n’est pas ajouté au stock publié. La mise à jour se fait toutes les dix ticks, puis les signaux se propagent selon le fonctionnement normal du réseau logique. Les signaux entrants ne modifient pas les filtres ni les transferts. Les câbles restent connectés lorsque le quai tourne.

## Résumé pendant la conduite

Un panneau latéral affiche automatiquement le coffre du véhicule et le stock du quai lorsque vous occupez ou pilotez à distance un véhicule entièrement dans la zone. Les quantités sont regroupées par objet et qualité, avec le nombre d’emplacements occupés. Ce résumé est en lecture seule et reste consultable sans électricité.

Le panneau se ferme dès que vous quittez le véhicule, relâchez son contrôle distant ou que le véhicule sort de la zone. Il ne s’affiche pas pour une simple sélection distante ni pour une voiture laissée vide sur le quai.

## Développement

Structure reprise des autres mods du dossier : `data.lua` et `prototypes/` pour les prototypes, `control.lua` et `scripts/` pour le runtime, `graphics/` et `locale/` pour les ressources.

```sh
./build.sh test       # syntaxe, locales et tests Lua (Python 3 + liblua5.4)
python3 tests/circuit.py # lecture des réseaux rouge et vert, présence et cycle de vie
python3 tests/smoke.py # scénario dans le moteur Factorio installé
python3 tests/pyanodon.py # recette et déblocage avec le pack Pyanodon installé
python3 tests/migration.py # migration réelle du stock 50 → 100
python3 tests/visual_smoke.py # interface réelle et capture hors écran
python3 tests/summary_visual.py # résumé conducteur et pilotage distant réels
./build.sh package    # archive distribuable dans dist/
./build.sh devlink    # installation locale en lien dans ~/.factorio/mods
./build.sh unlink
```

`MODS_DIR` permet de choisir un autre dossier de mods. `FACTORIO_BIN` permet aux tests moteur de sélectionner le binaire. Les tests utilisent un profil temporaire isolé et ne modifient pas les sauvegardes du joueur.

Un changement du data-stage nécessite un redémarrage complet du jeu. `game.reload_mods()` ne recharge que le runtime. La constante de vérification se trouve dans `scripts/constants.lua`.

Le MVP ne comporte ni débit, ni quantité par filtre, ni conduite automatique. Les bras dessinés sont purement visuels.

Les scénarios vérifient les gestionnaires d’événements dans le moteur réel. Certains événements protégés ne peuvent pas être déclenchés par script : leurs gestionnaires sont alors appelés directement avec des entités ou éléments d’interface réels. La validation graphique s’exécute hors écran, sans intervenir dans une partie ouverte, et indique où trouver sa capture et ses journaux.

Le voyant sur la bande technique est orange en attente, vert lorsqu’un seul véhicule est entièrement stationné et arrêté, et éteint sans alimentation. Le vert confirme la détection même si aucun objet n’est transféré. Sans courant suffisant, les transferts s’arrêtent.

Les quais déjà posés passent automatiquement à 100 emplacements : contenu et réglages sont conservés, une ancienne limite sans restriction s’étend à tout le nouveau stock et une limite manuelle reste inchangée.

Les textes et captures destinés au portail sont préparés dans `portal/`. La vignette `thumbnail.png` est incluse à la racine de l’archive.

La recette utilise 20 plaques de fer, 20 engrenages, 10 circuits électroniques et 2 coffres en fer. Avec Pyanodon Petroleum Handling, les engrenages sont remplacés par 20 petites pièces de niveau 1 (`small-parts-01`) et les 10 circuits électroniques par 5 moteurs (`engine-unit`). Le déblocage suit la recherche Automobile du pack.
