# Vehicle Loading Dock

**Vous conduisez, le quai s’occupe de la cargaison.**

Vehicle Loading Dock ajoute un quai qui charge et décharge automatiquement le coffre d’un véhicule stationné. Une aide logistique pour le début et le milieu de partie, avant une infrastructure ferroviaire ou robotique importante.

![Un véhicule correctement stationné et détecté par le quai](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/HEAD/portal/gallery/02-vehicule-detecte.png)

## Un stationnement simple

Posez le quai, alimentez-le, choisissez vos filtres puis garez votre véhicule dans la zone libre. Il suffit que le véhicule soit entièrement dans la zone et à l’arrêt pour qu'il soit chargé/déchargé.

## Un stock tampon

Le quai possède un stock tampon de **100 emplacements**. Vous pouvez le remplir et le vider à la main ou avec des bras classiques.

Le transfert entre ce stock et le véhicule est automatique :

- **Chargement :** jusqu’à dix types d’objets, du quai vers le coffre du véhicule.
- **Déchargement :** jusqu’à dix types d’objets, du coffre du véhicule vers le quai.
- Le déchargement passe en premier, puis le chargement.
- Les transferts sont instantanés, dans la limite de la place réellement disponible.
- Les qualités et les métadonnées des objets sont conservées.

Les filtres n’imposent aucune quantité. Un objet peut figurer dans les deux listes : il est alors déchargé, puis rechargé.

![Configuration des filtres de chargement et de déchargement](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/HEAD/portal/gallery/03-configuration.png)

## Les stocks visibles depuis le véhicule

Lorsque vous occupez ou pilotez à distance un véhicule entièrement dans la zone du quai, un panneau latéral affiche automatiquement :

- le contenu du coffre du véhicule ;
- le contenu du stock du quai ;
- les quantités regroupées par objet et par qualité ;
- le nombre d’emplacements occupés dans chaque inventaire.

![Résumé automatique des stocks du véhicule et du quai](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/HEAD/portal/gallery/04-resume-stocks.png)

## Voyant de stationnement

Un voyant sur la bande technique indique l’état du quai :

- **Orange :** quai alimenté, en attente d’un seul véhicule correctement stationné.
- **Vert :** un véhicule compatible est entièrement dans la zone et à l’arrêt.
- **Éteint :** alimentation insuffisante ; les transferts sont suspendus.

![Quai alimenté en attente d’un véhicule, voyant orange](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/HEAD/portal/gallery/01-attente.png)

## Déblocage et construction

Le quai se débloque avec la recherche **Automobile**.

**Recette :** 20 plaques de fer, 20 engrenages, 10 circuits électroniques et 2 coffres en fer.

Avec **Pyanodon Petroleum Handling**, les 20 engrenages sont remplacés par **20 petites pièces de niveau 1** (`small-parts-01`) et les 10 circuits électroniques par **5 moteurs** (`engine-unit`). Le quai reste débloqué par la recherche Automobile du pack.

**Électricité :** consommation fixe de **30 kW**. Le quai doit être couvert par un réseau électrique alimenté.

## Véhicules compatibles

Voitures, chars et spidertrons, ainsi que les véhicules de mods utilisant les types `car` ou `spider-vehicle` avec un coffre compatible.

Seul le coffre est manipulé. Le carburant, les munitions et les équipements ne sont pas transférés.

## Réglages et sauvegardes

Les plans mémorisent les filtres. Après minage et repose du quai, les filtres sont vides. La copie directe des réglages entre quais n’est pas prise en charge. La rotation conserve le stock et est refusée si la nouvelle bande technique est occupée.

## Compatibilité

**Factorio 2.1 uniquement.** Aucun autre mod n’est requis. Les textes du mod sont disponibles en français et en anglais.

La recette s’adapte à Pyanodon Petroleum Handling. Nullius et Ultracube ne font pas l’objet d’une compatibilité dédiée dans cette version.

## Code source et retours

[Code source](https://github.com/Kardorio/vehicule_loading_dock) · [Signaler un problème](https://github.com/Kardorio/vehicule_loading_dock/issues)
