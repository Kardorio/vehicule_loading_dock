# Direction artistique des ressources

## Génération

Outil intégré `image_gen`, deux générations originales à fond transparent : `graphics/dock-sheet.png` et `graphics/icon.png`. Aucun assemblage ou recadrage destructif : les cellules sont sélectionnées directement par les prototypes Factorio.

## Consigne de la planche

Créer une planche carrée de quatre vues orthographiques du même quai industriel, nord/est/sud/ouest. Empreinte carrée de huit cases, bande technique sur un seul bord, aire de stationnement libre. Esthétique de bâtiment Factorio : acier patiné, volumes et biseaux, rouille discrète, tuyaux hydrauliques, petites lampes ambre, marquages jaunes usés et deux bras de manutention repliés. Éclairage en haut à gauche. Béton sombre, traces d’huile et flèches discrètes ; ni véhicule, ni personnage, ni toit, ni texte. Les bras sont graphiques uniquement.

Résultat : PNG RGBA de 1254×1254, quatre cellules de 627×627. Le calque `lower-object` conserve les véhicules au-dessus du dallage.

## Consigne de l’icône

Créer une icône représentant directement le gameplay : une voiture utilitaire blindée de couleur sable, stationnée sur une dalle carrée sombre, avec un quai étroit sur un seul bord et un bras hydraulique jaune dirigé vers le coffre. Vue légèrement plongeante de trois quarts, style industriel Factorio, métal patiné, silhouette lisible à petite taille, fond transparent, aucun texte.

Cette icône remplace la première proposition, dont la caisse entre deux bras ne représentait pas assez clairement le mod. Génération par l’outil intégré `image_gen`, prompt intégral dans `tools/icon-prompt.txt`.

Résultat : PNG RGBA de 1254×1254, mis à l’échelle par le moteur pour les emplacements d’inventaire. La planche du bâtiment validée reste identique.

## Vérification

Chargement dans Factorio 2.1.21 et capture hors écran du quai avec un véhicule stationné : `tests/artifacts/building.png`. Capture de l’interface : `tests/artifacts/interface.png`.
