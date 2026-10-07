# Reprise coordonnée — 7 octobre 2026

Demande explicite : reprendre l’audit et créer un commit distinct par correction. Le suivi précédent confirme le périmètre MacDown (aucun app/database). Aucun push, déploiement ou installation de l’application. Bilan-arret.md reste la photographie historique de l’arrêt précédent. Le présent audit reste en cours ; aucune validation finale générale n’est acquise.

## Lecture et analyse effectuées par le coordinateur

Relus intégralement : MPUtilities.h/m (574 lignes m, deux plages contiguës), FileURLInlining.m, NSDocumentController+Document.m, NSPasteboard+Types.m, NSString+Lookup.m, NSUserDefaults+Suite.m, NSTextView+Autocomplete.h/m (732 lignes m, trois plages), MPMainController.m (deux plages), MPHTMLResourceURLs.m, MPURLSecurityPolicy.m, MPFileWatcher.m, MPResourceWatcherSet.m, mermaid.init.js, updateHeaderLocations.js. Les empreintes enregistrées correspondent à ces versions effectivement lues. La lecture des autres fichiers utiles/tests est tracée dans les notes des surfaces ; aucune lecture complète de MPDocument final n’est déduite de ses hunks.

- Utilities : résolution ressources/thèmes et ordre override, helpers caractères, JavaScript→JSON UTF8/ownership/erreurs, dossiers temporaires privés/exclusifs, archives bundled, historique des hashes stock et prune limité par nom+empreinte. Les maps cachées restent réellement consommées, preuve editor-utilities ; aucun retrait legacy arbitraire.
- Clipboard et document creation : filtres protocoles, nil/empty, clipping plist typé, erreurs et refus écrasement avant création document ; sources d’entrée MainController/Editor suivies.
- Autocomplete : paires/smart-quotes/IME, wrapping/deletion, espaces/indentation/désindentation, liste/blockquote/indent continuation, marqueurs entiers et mapping sélection, titres et lignes blanches, mapped image privée. Les trois actions de document ont été migrées dans le même commit que le contrat marker-only. Les autres deltas MPDocument demandent encore relecture finale.
- Resources/watchers : attributs src/href, URLs relatives/file/remote/fragment et entity decoding, conservation query et remplacement t ; génération par chemin et identité des sources empêchent ancien retry après retrait/re-add. Lifecycle cancel ferme fd. Tests réels vnode requis et exécutés ci-dessous.
- JS : erreur Mermaid textContent et renouvellement DOM pendant Promise ; image standalone tient compte du texte voisin et anchor wrapper. Les tests adaptateur ne certifient pas les internals Mermaid fournisseur.

## Commits et traçabilité

Chaque correction est isolée dans Git avec son ID dans le message lorsque l’ID historique existe. Les tests partagés sont préparés dans l’index par méthodes/scénarios sans écraser le fichier de travail. Des commits de test séparés corrigent les fixtures découvertes à la reprise et n’affaiblissent pas le contrat : domaine persistant destination (registerDefaults est hérité), ligne réelle de dossier (NSURL de directory de fixture avait slash distinct), shortcut déclaré (AppKit adapte le clavier).

`git log --oneline 962df74..HEAD` fournit les commits exacts. Notes métier/causes/tests : editor-utilities.md, ui-preferences.md et nouvelles notes reprise-build/ui/pdf/PEG/rendering. Les nouvelles corrections sont séparées des versions héritées par snapshots de blobs dans /tmp, sans réinitialiser l’arbre partagé.

## Contrôles centralisés exécutés

Toutes commandes XCTest utilisent `xcodebuild test -workspace 'MacDown 3000.xcworkspace' -scheme MacDown -derivedDataPath build/DerivedData -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120`, avec `-only-testing` par classe/méthode ci-dessous. Xcode26.2, macOS local, hôte Debug. Aucun appel au smoke helper CI sur les préférences locales.

| ID | Portée / preuve | Résultat réel | Limite |
| --- | --- | --- | --- |
| R1 | MPUtilityTests + MPPDFAnchorInjectorTests ; /tmp/macdown-audit-reprise-tests.log | exit65 ; 59 tests, 5 assertions dans un seul test PDF ; 44 Utility réussis | Échec PDF confirmé, fixture corrigée ensuite ; source YAML encore antérieure aux nouvelles clés |
| R2 | PDF + URLSecurityPolicy + MainControllerMenu ; /tmp/macdown-audit-reprise-tests2.log | exit65 ; 37 tests, 1 échec menu ; 15 PDF et 17 URLSecurity réussis | PDF fixture dirtyRect vérifiée ; roundtrip ajouté ensuite |
| R3 | Preferences, Terminal, Sidebar, PreferencesResizability, HTMLResourceURLs, ResourceWatcherSet, PDF ; /tmp/macdown-audit-reprise-tests3.log | exit65 ; 179 tests, 2 échecs de fixtures dans tests nouveaux migration/sidebar | Autres classes réussies, dont PDF roundtrip et watchers réels ; fixtures révisées |
| R4 | MainControllerMenu + deux méthodes migration/sidebar échouées ; /tmp/macdown-audit-reprise-tests4.log | exit0 ; 7 tests réussis | Suites de livraison complètes restent à exécuter |
| R5 | Utility + Terminal + deux nouvelles méthodes headings app/QL ; /tmp/macdown-audit-reprise-tests5.log | exit65 ; build échoué, aucune validation de test | Macro XCTAssert et virgule Objective-C corrigées ; relance R6 en cours |
| R6 | Utility + Terminal + RendererState + QuickLookRenderer ; /tmp/macdown-audit-reprise-tests6.log | en cours | Consigner compte/code après fin réelle |
| JS | node MacDownTests/JavaScript/mermaid-init.test.js ; node MacDownTests/JavaScript/header-locations.test.js | exit0, deux Mermaid + quatre classifications | DOM adaptateur contrôlé ; fournisseur SVG non exercé |
| Portable | CLI/BuildTools/version/workflow/website/pluriels | résultats précis dans reprise-build.md et reprise-ui.md | Environnements isolés ; API GitHub/GUI/signatures distantes non exécutées |

Les xcresult sont conservés dans build/DerivedData/Logs/Test ; les logs /tmp ne constituent pas des artefacts pérennes du dépôt. Les nouvelles sources peuvent rouvrir un résultat précédent ; aucun succès d’un ancien lot ne certifie les deltas suivants.

## Points de reprise ouverts

- Finir commit des corrections héritées rendering/MPDocument/PDF/PEG/project et localisations, puis nouvelles corrections avec leurs régressions.
- Relecture intégrale finale MPDocument, carte des parcours et seconde passe des consommateurs (dont ordre DOM/PDF, liens multipage, UTF8/NUL, scopes et rendu frais). Le highlighter initial inverse extensionFootnotes (pmh_EXT_NOTES vs NONE), signal statique à confirmer avec test.
- Consolider les preuves sources nouvelles et SHA divergents ; réconcilier tous fichiers source, exclusions et nouveaux fichiers. Un test PDF accidentellement inscrit dans inventaire principal est retiré des compteurs et reste tracé dans les notes PDF.
- Suites complètes, builds propres Debug/Release/universal et gates applicables restent non exécutés sur le code final. Aucune affirmation « prêt à livrer ».
