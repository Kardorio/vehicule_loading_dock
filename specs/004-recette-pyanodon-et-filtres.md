# Recette Pyanodon et cycle de vie des filtres

Demande validée : adapter la recette au pack Pyanodon joué, garder les filtres dans les plans et retirer leur conservation après minage ainsi que la copie directe des réglages.

- La recette de base emploie 20 plaques de fer, 20 engrenages, 10 circuits électroniques et 2 coffres en fer.
- Avec `pypetroleumhandling`, qui définit `small-parts-01`, remplacer les 20 engrenages par 20 petites pièces de niveau 1 et les 10 circuits électroniques par 5 moteurs (`engine-unit`), du même type que ceux de la voiture. La dépendance est optionnelle ; le déblocage reste sur Automobile et suit donc les modifications du pack.
- Le minage restitue le stock sans inscrire les filtres dans l’objet. Une pose avec un ancien objet portant des tags ignore ces réglages.
- Les plans conservent les deux listes, y compris les emplacements non consécutifs. Le clonage reste cohérent.
- Reporter les modifications éditoriales françaises dans la description anglaise sans réintroduire les paragraphes retirés.
- Valider le cycle de vie dans le moteur de base et le chargement de la recette avec le pack Pyanodon local dans un profil isolé.
