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

Le GIF ouvre les descriptions française et anglaise : boucle de 18,4 secondes, 880×704 pixels, 8 images par seconde, environ 16,5 Mo. La lecture est accélérée de 50 %. Chaque départ attend le vidage effectif des tapis, du quai et des bras de déchargement, puis laisse une seconde de pause avec les tapis vides à l’écran. Le dernier déchargement est également terminé avant la fin de la boucle.

La capture peut être reproduite avec la sauvegarde de démonstration d’origine :

```sh
python3 tools/record_portal_demo.py --save "/chemin/vers/test vehicule loading.zip"
```

Le script utilise Factorio, FFmpeg, Python 3, NumPy et Pillow ; ImageMagick est facultatif. Il travaille sur une copie temporaire de la sauvegarde. Les filtres du coffre du véhicule limitent la cargaison à une pile de fer et une pile de minerai d’uranium pour montrer des lots finis. Les états des tapis sont contrôlés dans le moteur avant chaque départ.
