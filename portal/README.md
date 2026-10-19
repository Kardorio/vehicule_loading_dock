# Éléments de publication

Ce dossier prépare la fiche du portail ; aucune publication n’est exécutée.

- `description.en.md` : présentation anglaise à copier dans le champ de description du portail.
- `description.fr.md` : version française correspondante pour relecture.
- `metadata.json` : titre et résumé court, cohérents avec le mod.
- `../thumbnail.png` : vignette issue de l’icône validée, également intégrée à l’archive du mod.
- `gallery/` : captures réelles du quai en attente, du quai avec un véhicule détecté de l’interface de configuration à 100 emplacements et du résumé latéral pendant la conduite.

L’archive du mod est produite par `./build.sh package` dans `dist/`. La vignette est conservée dans sa définition originale carrée avec transparence ; le portail peut l’afficher en petite taille. La documentation officielle recommande idéalement une vignette de 144×144 pixels, sans imposer cette dimension : https://lua-api.factorio.com/latest/auxiliary/mod-structure.html

La version 1.0.0 est préparée pour la première publication. Le changelog de cette première version est validé. La licence du code est fournie dans `../LICENSE`.

## Liens des images

Les deux descriptions intègrent les quatre captures avec des liens absolus :

`https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/master/portal/gallery/<image>.png`

`master` désigne explicitement la branche contenant les captures. Les images doivent être présentes dans ces chemins et accessibles publiquement pour que les liens fonctionnent sans authentification. La préparation du paquet ne change pas la visibilité du dépôt et ne publie pas la fiche du portail.

## Démonstration animée

`gallery/05-demonstration.gif` présente un aller-retour entre deux quais échangeant des plaques de fer et du minerai d’uranium, capturé dans un profil Factorio isolé. Les deux stations sont rapprochées à 18 cases entre leurs centres, sur une surface de démonstration isolée. Le cadrage fixe resserré montre les deux stations simultanément et agrandit les quais et les objets transportés. Le terrain est retiré et le fond est transparent ; les quais, leurs marquages, les installations et les voyants sont conservés. La sauvegarde d’origine n’est pas modifiée.

Le GIF ouvre les descriptions française et anglaise : boucle de 6,6 secondes, 880×704 pixels, 8 images par seconde, environ 5,8 Mo.
