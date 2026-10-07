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

## R7 — Relecture projet et contrôle des regressions

Lecture intégrale du projet Xcode : plages contiguës 1–120, 121–300, 301–450, 451–600, 601–800, 801–1200, 1201–1600, 1601–2000, 2001–2400, 2401–2891. Les sorties tronquées préalables ne sont pas comptabilisées. Examen objets sources/headers/resources, dépendances cibles/subprojects, shell phases/entrées/sorties, variants localisés, SDK/debug/release/test flags, frameworks et embedding. Groupes référencent parfois les mêmes sources sous deux IDs : buildfiles sélectionnent une seule unité par cible ; aucun second pipeline runtime déduit de ces doublons d'affichage. Ancienne référence PAPreferences dans groupe Frameworks sans buildfile actif conservée : aucun changement spéculatif. Génération partagée MacDownResources ordonne styles/Prism avant application et Core sans cycle app→extension→Core→app. Copie Core purge ressources précédentes. Contrôle final clean Debug/Release et bundles encore ouvert.

Suite complète `/tmp/macdown-audit-reprise-full-tests.log` : 1 408 tests, 8 échecs (7 rendus/fixtures, 1 test reload sans fileURL). Aucune validation globale. Contrôle R7 ciblé `/tmp/macdown-audit-reprise-tests7.log` : ExternalChangeReload 31/31 réussi après précondition et scénarios Save As/close ; nouveau test footnotes en échec (4 assertions), diagnostic en cours.

- `MacDown 3000.xcodeproj/project.pbxproj` SHA-256 `852cce645681a4d471680d8c2e8001e73a2f1d1a9f6c1517ed6b695aa3654dd9` : lu/analyse intégral, validation ouverte.

- `MacDown 3000.xcodeproj/project.xcworkspace/contents.xcworkspacedata` SHA-256 `7f3b00b5c3fdb45242d7b87e1e5c4e25d1fa8129a16c94295ecc4e8ea2235c5f` : lu/analyse intégral, validation ouverte.

## R8 — Suite globale réussie

`xcodebuild test -workspace 'MacDown 3000.xcworkspace' -scheme MacDown -derivedDataPath build/DerivedData -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120` : exit0, 1 416 tests / 0 échec, 18,551s. Log `/tmp/macdown-audit-reprise-full-tests3.log`, résultat `build/DerivedData/Logs/Test/Test-MacDown-2026.10.07_20-23-52-+0200.xcresult`. Suite précédente full2 n'a pas exécuté de tests : compilation du nouveau test Lifecycle échouait faute de déclaration privée de parseMarkdown ; déclaration category ajoutée puis full3 passé. Le premier oracle footnote pmh_NOTE était erroné : règle grammar ne remplit pas ce type. Oracle final observe l'analyse réelle d'une référence note contenant une emphase ; aucune modification du parser pour satisfaire le test.

Vrai NSBundle du produit Debug : `/tmp/macdown-localization-bundle-contracts 'build/DerivedData/Build/Products/Debug/MacDown 3000.app'` réussi, domaines da/fi/he/hi/uk trouvés ; titres traduits et formes 1/2/5 consommées par JJPluralForm réel.

Core/QL headers/plists/prefs/entitlements relus intégralement. Point ouvert QL preference sandbox : extension sandbox lit suite application sans app group ni exception shared-preference ; la documentation Apple UserDefaults init(suiteName:) exige une entitlement adéquate pour accéder à un autre domaine. Vérification isolée sandbox en préparation ; le résultat des tests unitaires unsandboxed ne prouve pas cet accès. Sources primaires : https://developer.apple.com/documentation/foundation/userdefaults/init%28suitename%3A%29 et https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html .

Build propre universel Debug en cours dans `build/AuditDebug`, Release à suivre. Validation globale encore ouverte.

## R9 — validations complémentaires et état actuel

- Suite complète avant refonte PDF native : 1 416 tests, zéro échec, exit0 ; `/tmp/macdown-audit-reprise-full-tests3.log`, xcresult `build/DerivedData/Logs/Test/Test-MacDown-2026.10.07_20-23-52-+0200.xcresult`. Cette réussite ne certifie pas les sources PDF modifiées ensuite.
- Builds propres Debug et Release : arm64 et x86_64, exit0, produits `build/AuditDebug` et `build/AuditRelease`. Warning Release de versions extension/app divergentes confirmé, correction `c91b9f9` à contrôler sur le prochain produit réel. Signature de distribution non exécutée.
- Sandbox réel corrigé dans `6e8d0db` ; essais signés ad hoc, CFPreferences réellement consommé, lecture autorisée/refus écriture. Voir reprise-quicklook-sandbox.md pour nettoyage et portée.
- 47 tests Lifecycle passent après ajout de cinq assertions de parcours consommateur, `/tmp/macdown-audit-lifecycle-more2.log`, xcresult 20-37-00 ; premier essai arrêté à compilation faute d’import JSContext, réparé avant exécution.
- Lint configuré CI : `npx --yes --package markdownlint-cli markdownlint README.md CHANGELOG.md CONTRIBUTING.md MacDown/Resources/help.md MacDown/Resources/contribute.md`, exit0, `/tmp/macdown-audit-markdownlint.log`. Dépendance exécutée dans le cache npm, aucune installation globale ni modification du dépôt.
- Réconciliation physique : chaque racine de l’inventaire parcourue récursivement, fichiers cachés compris, `os.walk(...,followlinks=False)`, exclusions tiers/build appliquées et `Tools/GitHub-style-generator/node_modules` (dépendances installées) exclu explicitement. Aucun fichier absent de l’inventaire ou de sa liste d’exclusions, aucun fichier inventorié disparu, aucun lien symbolique. Nouveaux tests et preuves restent hors compte du code applicatif. À répéter après dernières créations source PDF éventuelles.
- Seconde passe sécurité URL : MPURLSecurityPolicy.m et MPHTMLResourceURLs.m entièrement relus. Résolution composant final/symlinks et frontière slash protègent la portée des ouvertures ; POSIX/UTI protègent les exécutables. MPGetDataMap consomme seulement les archives `.map` du bundle, pas une archive de document importé. Pas de finding démontré pour ces chemins ; ne pas transformer la dépréciation de l’API d’archive en faille non prouvée.
- Traductions restantes commités séparément après comparaison des IDs aux actions XIB (reading, bold, indent, find, recent documents, Mermaid). Tous les `.strings` modifiés passent `plutil -lint`. Aide frontmatter et extension `.style` corrigées chacune dans un commit.

Gates encore ouverts : pipeline PDF natif et réouverture après export, version paquet finale, tests UI, suite complète après dernières corrections, seconde passe globale et validation finale des empreintes.

### R10 — gate UI tenté, blocage environnement confirmé

`xcodebuild test -scheme MacDownUITests`, `/tmp/macdown-audit-ui-acceptance.log`, xcresult `build/DerivedData/Logs/Test/Test-MacDownUITests-2026.10.07_20-39-10-+0200.xcresult`, exit65. Compilation/liaison et lancement runner réussis ; aucune des quatre fonctions de test UI n’a démarré. XCTest signale `Timed out while enabling automation mode.` après60s. `DevToolsSecurity -status` indique `Developer mode is currently disabled.` : condition environnement distincte d’un défaut application, sans établir que ce réglage est la seule cause. Pas de permission système élargie, pas de contournement, pas de fake succès. La suite UI reste non validée ; xcresult compte seulement l’échec d’initialisation du runner.

Le smoke script CI réinitialise explicitement les domaines de préférences utilisateur et exige `GITHUB_ACTIONS=true`. Il n’est pas exécuté en forgeant ce flag sur le poste utilisateur. Ses tests de migration isolés sont verts, mais ne certifient pas le lancement/migration réel sur un runner propre. Ne pas classer le script CI comme legacy : workflows smoke/release le consomment.

## R11 — contrats autonomes reliés à CI

Les tests natifs ajoutés pendant l’audit vivaient hors target XCTest. Le workflow test les exécute désormais explicitement avant la suite Xcode, dans chaque matrice macOS14/26, avec timeout5min et arrêt immédiat sur erreur. Une seule étape, mêmes scripts qu’exercés pendant l’audit, pas de mock ajouté pour la CI. Aucun appel de publication/signature distribution.

Exécutés de nouveau localement : scripts_tests7scénarios, stall_empty_suite, version_tests, packaging_version_tests, peg_contracts UBSAN, print_colors6titres/PDFKit, mermaid-init2 et header-locations4 : tous exit0. preferences_tests Sandbox signé a déjà passé avant son commit6e8d0db ; pas de répétition inutile du test créant des conteneurs macOS. YAML workflow chargé par Ruby, git diff --check vert. Le job GitHub distant n’a pas été lancé ; ces contrôles locaux ne certifient pas les deux OS distants.

Lecture intégrale finale du workflow test affiché sans troncature, chaque déclencheur, job, timeout, permission, step et branchediagnostic examiné. SHA-256 `9501da350496f41e13090b35dec33eda2afdd15f2963316ebf57b17aaba2683b`.

Produit Debug real : deux plists application/extension portent CFBundleVersion1570 et shortversion3000.0.7-rc.1.post159 ; ValidateEmbeddedBinary exécuté sans avertissementversion. Signature ad hoc extension vérifiée strictement ; entitlement réel embarqué contient domaineexactread-only. Xcode injecte des exceptions supplémentaires dans ses produits de test, distinctes de la politique source et du test Sandbox autonome. Release final à contrôler après correction PDF.
