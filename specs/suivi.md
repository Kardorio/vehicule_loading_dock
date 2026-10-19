# Suivi de réalisation

- Implémentation autonome dans le dossier fourni, sans opérations Git (aucun dépôt valide).
- Phase 1 : terminée ; tests Lua géométrie, détection, filtres, transfert et conservation des piles.
- Phase 2 : terminée ; inventaire composite, GUI native, cycle de vie, plans et copies de configuration.
- Phase 3 : scénario moteur Factorio 2.1.21 réussi après sauvegarde/rechargement, inserters réels, voiture/spidertron et clonage de zone. Essai GUI graphique réussi hors écran, capture inspectée.
- Défauts corrigés par les vérifications : fluidbox de rotation, masques de collision, minable_flag 2.1, tags à indices creux, adoption des coffres déjà clonés, cible des inserters.
- Revue finale indépendante : aucun défaut restant dans le périmètre examiné. Correctif supplémentaire vérifié : lecture des tags de l’objet de construction porté par un robot.
- Couverture : aucun outil ni seuil antérieur dans ce nouveau projet ; aucun pourcentage annoncé. Tests comportementaux et scénario moteur utilisés.
- Changelog : aucun fichier ajouté sans validation de Geoffrey ; aucune version publiée.
- Graphismes : sprites et icône détaillés générés avec image_gen, intégrés et inspectés en jeu. Captures dans tests/artifacts/.
- Publication/installation dans le profil du joueur : non effectuée. Archive de développement dans dist/.
- Équilibrage initial ajusté après essai joueur ; compatibilité de recette Pyanodon ajoutée dans l’évolution 004. Nullius et Ultracube restent sans compatibilité dédiée.

## Bilan du cycle

Résultat : A pour le périmètre MVP testé localement. Processus : C, plusieurs vérifications et revues ont été nécessaires. Les contrôles ont détecté les différences de l’API 2.1, la sérialisation des filtres, le cycle de clonage et les tags de construction par robot. Aucun défaut ouvert issu des revues ; pas de pourcentage de couverture inventé.

## Évolution 002 — Retour des essais en jeu

Électricité fixe 30 kW, stock de 100 emplacements, voyant orange/vert/éteint réalisés. Tests unitaires, scénario moteur, migration native et inspection graphique validés. Revue indépendante sans défaut ouvert. Un test graphique a été ajusté pour attendre le chargement électrique et éviter l’ordre des callbacks du même tick ; aucun contournement du contrôle d’alimentation. Les régressions de clonage vérifient aussi une limite volontaire à 50 dans les nouveaux inventaires de 100.

Éléments de portail : thumbnail.png, portal/description.fr.md, portal/metadata.json et trois captures de galerie. Pas de publication ni de changement de version/changelog sans choix de Geoffrey. Archive de développement et lien local remis à jour après emballage.

## Évolution 003 — Résumé de conduite

Panneau latéral non modal, indépendant par joueur et en lecture seule. Suivi du véhicule courant, y compris pilotage distant ; jamais du seul véhicule physique ou d’une sélection distante. Mise à jour des stocks après les transferts toutes les dix ticks ; fermeture immédiate par événement et garde géométrique chaque tick pour les seuls panneaux ouverts.

Tests Lua, régressions moteur et scénario graphique natif réussis. Les essais réels ont détecté deux incompatibilités d’interface (style de frame et nom items réservé), corrigées avant livraison. La validation distante distingue explicitement tank actif et voiture physique du personnage. Revues indépendantes sans défaut restant. Capture et présentation du portail mises à jour.

Phrase d’aide sous les filtres remplacée par une explication complète ; label multiligne. Aucun numéro de version, changelog ou publication modifié.

## Évolution 004 — Recette et filtres

Ajustement demandé après relecture : recette en fer, variante Pyanodon Petroleum Handling avec petites pièces de niveau 1 ; filtres conservés par les plans, supprimés après minage et non copiables directement entre quais. Les descriptions FR et EN suivent la relecture utilisateur.

Validation : tests Lua et scénario moteur de base réussis ; minage et repose sans filtres, paramètres des plans restaurés, recette en fer et copie directe désactivée. Le pack Pyanodon complet installé charge dans un profil isolé ; la recette avec petites pièces et le déblocage Automobile sont vérifiés dans le moteur.

Retour suivant : dans la variante Pyanodon Petroleum Handling, les 10 circuits sont remplacés par 5 moteurs du même type que ceux de la voiture. Test du pack complet réussi : recette sans circuits, moteurs communs avec la voiture et déblocage Automobile vérifiés. Documentation FR/EN actualisée.

## Préparation de la version 1.0.0

Version choisie par Geoffrey après validation en sandbox et dans sa partie. Changelog initial validé, avec la formulation « quai de chargement et de déchargement ». Tests Lua, syntaxe/locales et scénarios moteur de base et Pyanodon réussis sur la version 1.0.0. Aucune publication sur le portail effectuée par cette préparation.
