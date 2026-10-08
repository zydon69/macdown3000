# Corrections Document — preuves ciblées

Ces preuves ne remplacent pas la nouvelle lecture intégrale finale demandée le 9 octobre 2026.

## Garde Setext après ATX

La première correction Setext `adf7eed` utilisait un oracle trop permissif : Hoedown rend `# Title\n===` comme un seul titre, en ignorant la seconde ligne. Ce résultat ne prouve pas que cette ligne appartenait au titre. La correction intermédiaire pouvait donc supprimer `===` lors d'une conversion.

Le candidat précédent doit désormais produire, seul, un paragraphe et produire avec l'underline un titre. Le test autonome `testPreviewSetextProofDoesNotConsumeUnderlineAfterATX` protège les octets voisins ; les deux parcours (underline suivante et interne) partagent cette preuve. Test vert réel dans `build/SquashedPreviewAudit/popup-queue-red-setext-green.log`. Il s'agit d'une régression de notre correction intermédiaire, pas d'un défaut attribué au code initial.

## Identité DOM des contrôles

Les IDs et attributs rédigés dans le Markdown ne sont pas une preuve d'identité des contrôles injectés. La référence privée JS `elements()` fournit panneau, style et spans possédés ; le scanner et le remplacement du body utilisent ces seules références. Les éléments détachés sont filtrés une fois, avant la marche DOM. Les propriétés globales nommées par un ID HTML doivent également exposer la fonction attendue avant son appel.

La régression WebView conserve les div/style/panneau/erreur/attribut run de l'auteur, applique du gras, conserve la sélection et vérifie un remplacement rapide par sentinelle. Elle vérifie aussi une vraie case de tâche, puis son clic et la mutation `[x]` du Markdown. Avec les flags de renderer réellement activés, ce dernier clic échoue avant les gardes Prism/MathJax : `real-fixtures-collision-red.log` ; après correction les 11 scénarios passent dans `targets-real-fixtures-green.log` (73,826 s). Les fixtures antérieures sans `rendererFlags` corrects ne sont pas retenues comme preuve de ce défaut. Le jeton assure fraîcheur/provenance, pas une frontière d'autorisation contre du JavaScript déjà exécuté dans le même contexte.
