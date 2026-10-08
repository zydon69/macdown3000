# Corrections Document — preuves ciblées

Ces preuves ne remplacent pas la nouvelle lecture intégrale finale demandée le 9 octobre 2026.

## Garde Setext après ATX

La première correction Setext `adf7eed` utilisait un oracle trop permissif : Hoedown rend `# Title\n===` comme un seul titre, en ignorant la seconde ligne. Ce résultat ne prouve pas que cette ligne appartenait au titre. La correction intermédiaire pouvait donc supprimer `===` lors d'une conversion.

Le candidat précédent doit désormais produire, seul, un paragraphe et produire avec l'underline un titre. Le test autonome `testPreviewSetextProofDoesNotConsumeUnderlineAfterATX` protège les octets voisins ; les deux parcours (underline suivante et interne) partagent cette preuve. Test vert réel dans `build/SquashedPreviewAudit/popup-queue-red-setext-green.log`. Il s'agit d'une régression de notre correction intermédiaire, pas d'un défaut attribué au code initial.
