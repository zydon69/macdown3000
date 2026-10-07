# Reprise PDF — 7 octobre 2026

Cette note complète `pdf-anchors.md`, sans remplacer ses preuves historiques.

## Lecture et analyse

`MPPDFAnchorInjector.h` (74 lignes) et `.m` (351 lignes) lus intégralement à la reprise. `MPPDFAnchorInjectorTests.m` lu intégralement, puis version finale relue en plages contiguës 1–400, 401–800, 801–1200, 1201–fin après modification. La constante JavaScript, `readAnchorLinks:headings:` et le consommateur `postProcessExportedPDFAtURL:` de `MPDocument.m` ont été examinés comme dépendances ; cela ne certifie pas le reste de MPDocument.

| Fichier | SHA-256 analysé | Lecture | Analyse | Validation |
| --- | --- | --- | --- | --- |
| `MacDown/Code/Document/MPPDFAnchorInjector.h` | `558508dae940e858e83675149f6f271dae75b3d84ffca106abf506543c09ba40` | intégrale | intégrale | en attente des contrôles centralisés |
| `MacDown/Code/Document/MPPDFAnchorInjector.m` | `b8f20104ec80990652b864742864fd0b6e6662cf8c6986cbae67027d78a6e590` | intégrale | intégrale | en attente des contrôles centralisés |
| `MacDownTests/MPPDFAnchorInjectorTests.m` | `0797c602b0dc58c08542e703ab72a3376753279e98f14bd3da1d37eddc4b7294` | intégrale finale | intégrale | en attente des contrôles centralisés |

Symboles et branches examinés : deux factories et leurs propriétés copiées ; chaîne vide ; snapshot immédiat PDFSelection/pages/bounds ; document absent/vide ; dictionnaire de slugs avec premier titre ; needles distinctes et erreurs PDFKit ; comptage et avancement par texte ; sélection explicite avec cardinalité et index borné ; contrat TOC-only ; destination inconnue/absente ; pages canoniques ; construction annotation/action et isolation d'un lien défectueux. Aucun code obfusqué constaté dans ces fichiers. Coût : une recherche PDF par texte distinct, snapshots limités à leurs résultats ; aucune recherche répétée par lien.

## REPRISE-PDF-01 — texte invisible dupliqué dans la fixture

Le contrôle initial `/tmp/macdown-audit-reprise-tests.log` exécute 59 tests, avec 5 assertions échouées dans un seul test, `testInlineLinkAfterHeadingTargetsEarlierHeading`. Sa première assertion constate **3 occurrences PDF recherchables pour 2 items dessinés**. Les quatre suivantes découlent du refus légitime de l'injecteur lorsque la cardinalité attendue 2 diffère du PDF 3.

Cause identifiée : `MPPDFTestPrintView.drawRect:` réémet tous les items à chaque passe de page, y compris hors du rectangle à dessiner. Le clipping visuel ne garantit pas que le texte émis hors page disparaisse de son flux PDF recherchable. Correction : n'émettre `drawAtPoint:` que si le rectangle de texte intersecte `dirtyRect`. L'impression AppKit et la recherche PDFKit restent réelles ; aucun mock, aucun filtrage a posteriori des résultats, assertion exacte 2 conservée. Cause proposée à confirmer par la relance réelle centralisée.

Le même test vérifie désormais la persistance : PDF annoté sérialisé, rouvert avec PDFKit, action GoTo relue et destination vers la page et le point du titre antérieur. Les contrôles de type/count précèdent les lectures dépendantes ; un échec reste un échec et n'est pas remplacé par une assertion sur `nil`.

État : **corrigé à vérifier**. Aucun Xcode lancé par cet agent, pour préserver la sérialisation des contrôles orchestrés.

## Seconde passe et hypothèses restantes

- Le runtime MPDocument construit toujours les modèles avec indices explicites ; la compatibilité TOC-only est utilisée par les fixtures historiques, pas par l'export actuel. Elle est un contrat documenté, pas un repli après refus de cardinalité : la branche explicite fait `continue` sans retomber sur l'heuristique.
- Les liens vers des titres antérieurs et les répétitions de prose ne doivent jamais être interprétés comme une TOC. Les tests explicites couvrent ces cas, ainsi que l'exclusion indépendante d'une source/destination dont la cardinalité diffère.
- L'égalité des cardinalités ne prouve pas à elle seule l'égalité de l'ordre DOM/PDF. Une feuille d'impression qui réordonne visuellement les mêmes textes constitue une hypothèse déterminante à éprouver au niveau WebView/export ; elle a été signalée au coordinateur. Ne pas annoncer une garantie pour tout CSS arbitraire.
- Les selections multi-page ne sont représentées que par leur première page ; la prise en charge d'un lien long à cheval sur deux pages n'est pas démontrée par les fixtures courtes actuelles. Cette limite préexistante doit rester visible lors de la validation du flux complet.

Prochaine action : contrôle ciblé inline puis suite PDF centralisés, inscription des résultats réels, résolution de l'hypothèse d'ordre avant validation globale du flux.
