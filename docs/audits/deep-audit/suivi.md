# Deep audit — campagne03, départ de zéro

Statut : **en cours, non prêt à livrer**. Début : 8 octobre2026. Baseline `895d6c95b730dd8c98b7eb4b2fdac179c3407c29` ; arbre source propre. Campagne02 archivée dans [historique/campagne-02-895d6c9](historique/campagne-02-895d6c9/suivi.md). Aucun fichier de la nouvelle campagne n'est certifié par l'ancienne revue.

## Périmètre

MacDown est une application Objective-C/C, AppKit/WebKit/JavaScript, Xcode/CocoaPods ; aucun dossier Laravel app/database n'existe. Le périmètre couvre les mêmes racines propres, redécouvertes physiquement : MacDown, MacDownCore, MacDownQuickLook, macdown-cmd, sources propres Dependency, outils, manifests et workflows. Les tests/documentation/fournisseurs/artefacts sont consultés pour les contrats et preuves, avec exclusions explicitement requalifiées. Les deux archives actives sont incluses et devront être décodées à nouveau.

| Lot | Fichiers |
| --- | --- |
| root-document | 47 |
| build-cli-peg | 71 |
| ui-locales | 304 |
| rendering-pdf-quicklook | 60 |

## Exclusions de racines à réexaminer

- `Dependency/prism` : Sous-module tiers Prism : interfaces et intégration examinées, code fournisseur hors inventaire propre.
- `MacDown/Resources/Prism` : Assemblage généré depuis Dependency/prism.
- `Pods` : Dépendances CocoaPods installées.
- `build` : Compilations et sauvegardes locales, aucune donnée à auditer.
- `.git` : Métadonnées Git.
- `Tools/GitHub-style-generator/node_modules` : Dépendances npm installées ; manifestes et intégration examinés, code fournisseur hors inventaire propre.
- `.claude` : Configuration/instructions d’un autre assistant ; hors code applicatif et outils build exécutés.
- `assets` : Démonstration Markdown et screenshot du README, données utilisateur de démonstration et non code applicatif.
- `notes` : Documentation technique hors inventaire source.
- `plans` : Documentation de conception et de procédures hors inventaire source.
- `LICENSE` : Licences tierces et application, documentation légale sans code.
- `docs` : Documentation et suivi d’audit, hors inventaire source principal.
- `MacDownTests` : Tests et fixtures examinés pour les preuves, hors inventaire source principal.
- `MacDownUITests` : Tests UI examinés et exécutés pour les preuves, hors inventaire source principal.

## Inventaire exhaustif

| Chemin | SHA de découverte | Lu intégralement | Analysé intégralement | Validé | État | Preuve |
| --- | --- | --- | --- | --- | --- | --- |
| `.envrc.example` | `f8ec968e7ece` | ☐ | ☐ | ☐ | à lire | — |
| `.github/actions/build-macdown/action.yml` | `b8c590e20b14` | ☐ | ☐ | ☐ | à lire | — |
| `.github/actions/setup-macdown/action.yml` | `2c727a47459b` | ☐ | ☐ | ☐ | à lire | — |
| `.github/dependabot.yml` | `ae94084f7047` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/build-release.yml` | `327c09e26f78` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/markdownlint.yml` | `1e8a20d34f80` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/release.yml` | `f44f74aa3636` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/smoke-test.yml` | `961d97bd49db` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/staple-release.yml` | `6a61c84cc043` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/test.yml` | `c596922cc088` | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/update-website.yml` | `a9ddacf84f11` | ☐ | ☐ | ☐ | à lire | — |
| `.gitignore` | `3a2132614cc0` | ☐ | ☐ | ☐ | à lire | — |
| `.gitmodules` | `69be9ca5f02b` | ☐ | ☐ | ☐ | à lire | — |
| `.markdownlint.json` | `03709bc90f2e` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/YAML-framework/YAMLSerialization.h` | `68e864d1d3bb` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/YAML-framework/YAMLSerialization.m` | `982dd82f7b06` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlighter.h` | `bcaea22152ff` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlighter.m` | `f7d378231b6e` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlightingStyle.h` | `bbcf8aa4a4c0` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlightingStyle.m` | `f1fe70f79eee` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/Makefile` | `ba92d8bc7ce5` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/Makefile` | `ed0ae1de9349` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/compile.c` | `5881904b59c4` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.c` | `c673fb8467fc` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.g` | `41f4a5493cfe` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.h` | `bcdd2c5dc463` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/tree.c` | `43854b78d4ae` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/peg-markdown-highlight.xcodeproj/project.pbxproj` | `298977daa58b` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/peg-markdown-highlight.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | `14212f4d2947` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_definitions.h` | `3bb4ae80d27f` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_grammar.leg` | `7295f542e85a` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser.h` | `36724d84cf35` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser_foot.c` | `1204e603df3d` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser_head.c` | `a91476dcaad2` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_styleparser.c` | `ffc1ffd453ac` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_styleparser.h` | `abb30561fb61` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/tools/combine_parser_files.sh` | `c64a2e5286b3` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/version/Makefile` | `a657c7f788cd` | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/version/version.xcodeproj/project.pbxproj` | `9b87d0ce64c7` | ☐ | ☐ | ☐ | à lire | — |
| `Gemfile` | `f878fc8d64bc` | ☐ | ☐ | ☐ | à lire | — |
| `Gemfile.lock` | `ab1672163bc7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/project.pbxproj` | `bb83fc2aec27` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | `7f3b00b5c3fd` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/xcshareddata/xcschemes/MacDown.xcscheme` | `ee6421df4446` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/xcshareddata/xcschemes/MacDownUITests.xcscheme` | `fcd447a2bfaa` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/contents.xcworkspacedata` | `1f2050230d8c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | `dfa0f9bb85b9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | `c483c4d3281b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPExportPanelAccessoryViewController.h` | `656b07ee8787` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPExportPanelAccessoryViewController.m` | `e37f5bc7a153` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPMainController.h` | `243032702a66` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPMainController.m` | `888cb2af2d7d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPToolbarController.h` | `c45bee13d502` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPToolbarController.m` | `4cf8981f419d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPAsset.h` | `c1a03ae5c84d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPAsset.m` | `a4e260bd0ab2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPDocument.h` | `f70d0155da47` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPDocument.m` | `546d434a262c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPPDFAnchorInjector.h` | `7dbaa29df89e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPPDFAnchorInjector.m` | `902c57b2cb63` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPRenderer.h` | `45e93c4fd1c0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPRenderer.m` | `a939696a43b8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/DOMNode+Text.h` | `748eb6ded390` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/DOMNode+Text.m` | `4005d622d14d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSColor+HTML.h` | `ed1b5feb51f0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSColor+HTML.m` | `c97b507bf33b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSDocumentController+Document.h` | `502d752bb8dc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSDocumentController+Document.m` | `4af8a68681d5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSJSONSerialization+File.h` | `93948eae8346` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSJSONSerialization+File.m` | `2408f3ab942a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSObject+HTMLTabularize.h` | `1849ce0e2b22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSObject+HTMLTabularize.m` | `1d87c68ca646` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSPasteboard+Types.h` | `6d27da2a53fa` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSPasteboard+Types.m` | `d61025bbf8f5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSString+Lookup.h` | `8fcb13267c19` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSString+Lookup.m` | `9e18ee26f0cf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSTextView+Autocomplete.h` | `ea69f917e5a7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSTextView+Autocomplete.m` | `948afe284ee3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSUserDefaults+Suite.h` | `cac0f676b540` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/NSUserDefaults+Suite.m` | `e0b928949e2a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/WebView+WebViewPrivateHeaders.h` | `f537f69c38a0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/hoedown_html_patch.c` | `fd8a4612729a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Extension/hoedown_html_patch.h` | `763870f5ef85` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/MacDown-Prefix.pch` | `d68c3773ffcf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPEditorPreferencesViewController.h` | `5c9f8399882a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPEditorPreferencesViewController.m` | `6b12bf12fe47` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPGeneralPreferencesViewController.h` | `2a7d3a84426c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPGeneralPreferencesViewController.m` | `4b16b9ff667f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPHtmlPreferencesViewController.h` | `9beb7de62cc8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPHtmlPreferencesViewController.m` | `c3f923395429` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPMarkdownPreferencesViewController.h` | `8fbbe0a0a5ae` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPMarkdownPreferencesViewController.m` | `b6a006708eda` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferences.h` | `19d1fd4f6fff` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferences.m` | `313dd3a72396` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferencesViewController.h` | `fc5407141d5b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferencesViewController.m` | `640394689721` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPTerminalPreferencesViewController.h` | `585306c57bb4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPTerminalPreferencesViewController.m` | `1948d8a65946` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFileNode.h` | `40378502625b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFileNode.m` | `b86a626856e4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderSidebarViewController.h` | `ffb1bab4cc07` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderSidebarViewController.m` | `4bdfd6c0e625` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderWatcher.h` | `6fa9aa052021` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderWatcher.m` | `d26a83fe8cd7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSplitView.h` | `c9f56a108c5b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSplitView.m` | `5f8f7f2ba07d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSyncCoordinator.h` | `0e30d13c20f1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSyncCoordinator.m` | `bfa586bc60ac` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/FileURLInlining.h` | `c1696072c1ee` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/FileURLInlining.m` | `8b6cab69f85d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPAutosaving.h` | `798fb7bd3f3a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPFileWatcher.h` | `07689eb11b45` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPFileWatcher.m` | `ee5059ab5cd7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPGlobals.h` | `8ed8632ca58c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPHTMLResourceURLs.h` | `59696bfe884e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPHTMLResourceURLs.m` | `ead2d9ccec8a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPHomebrewSubprocessController.h` | `eb1e9070b3fe` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPHomebrewSubprocessController.m` | `0e7450785408` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPMathJaxListener.h` | `91ae4785b093` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPMathJaxListener.m` | `818553ca0a3a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPResourceWatcherSet.h` | `db6f55e8e1ba` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPResourceWatcherSet.m` | `d4663a4990d8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPURLSecurityPolicy.h` | `cff58c6ee4f0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPURLSecurityPolicy.m` | `ae6111380d3d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPUtilities.h` | `583fb5ceb495` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/MPUtilities.m` | `3e05f9cc43cf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPDocumentSplitView.h` | `625ea83042c7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPDocumentSplitView.m` | `a7c8b03e33c9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPEditorView.h` | `515c6983974c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPEditorView.m` | `a80f4075d2de` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/main.m` | `d806c4913d7b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/AppIcon.appiconset/Contents.json` | `2d55c952e547` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Contents.json` | `972ec1fd4232` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/Contents.json` | `972ec1fd4232` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesEditor.imageset/Contents.json` | `db68fe085f4b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesGeneral.imageset/Contents.json` | `4437fa77a297` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesMarkdown.imageset/Contents.json` | `92b86b6bd3ed` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesRendering.imageset/Contents.json` | `bb6d2d8f53c0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesTerminal.imageset/Contents.json` | `4b466f49b984` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/Contents.json` | `972ec1fd4232` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconBlockquote.imageset/Contents.json` | `a145b7675a7d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconBold.imageset/Contents.json` | `41bf3cb94a35` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconComment.imageset/Contents.json` | `189adf35c961` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconCopyHTML.imageset/Contents.json` | `c9ab4cc9bf4a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconEditorAndPreview.imageset/Contents.json` | `370f3fb8c7c9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading1.imageset/Contents.json` | `04d4084c9fc7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading2.imageset/Contents.json` | `5317ac258dcf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading3.imageset/Contents.json` | `6a0629705f23` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHideEditor.imageset/Contents.json` | `44ffc3693fa1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHidePreview.imageset/Contents.json` | `59d89fb85e49` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHighlight.imageset/Contents.json` | `78fcd02f8026` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconImage.imageset/Contents.json` | `5814d6124059` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconInlineCode.imageset/Contents.json` | `43d65364cf83` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconItalic.imageset/Contents.json` | `3dc3cf7bf3a1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconLink.imageset/Contents.json` | `66a9c81188d9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconOrderedList.imageset/Contents.json` | `a2a73d596add` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconShiftLeft.imageset/Contents.json` | `28502d4cf398` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconShiftRight.imageset/Contents.json` | `24b3e2d617c8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconStrikethrough.imageset/Contents.json` | `e77c50487d11` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconUnderlined.imageset/Contents.json` | `c0be5f16de2b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconUnorderedList.imageset/Contents.json` | `0e52a063bec8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/Contents.json` | `972ec1fd4232` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconBlockquote.imageset/Contents.json` | `4818ccf05ca4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconComment.imageset/Contents.json` | `8b4cd66e231a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconCopyHTML.imageset/Contents.json` | `88108c3b2480` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconEditorAndPreview.imageset/Contents.json` | `ab8403ee86d7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHeadings.imageset/Contents.json` | `97923d7fee5f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHideEditor.imageset/Contents.json` | `972d73619015` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHidePreview.imageset/Contents.json` | `fd0629ddb48d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHighlight.imageset/Contents.json` | `db5ed08775e0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconImage.imageset/Contents.json` | `95cb5853898b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconInlineCode.imageset/Contents.json` | `351cc8890128` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconLink.imageset/Contents.json` | `8a53098a4321` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconOrderedList.imageset/Contents.json` | `b16b171adfa1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconShiftLeft.imageset/Contents.json` | `2546f3fef2a1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconShiftRight.imageset/Contents.json` | `8dfa5a1fb64c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconStrikethrough.imageset/Contents.json` | `3e19d7de15db` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconUnorderedList.imageset/Contents.json` | `dd5a37ede0b9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPDocument.xib` | `ac4899e95d5a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPEditorPreferencesViewController.xib` | `63ba27c5cabb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPExportPanelAccessoryViewController.xib` | `d8d09ea196bc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPGeneralPreferencesViewController.xib` | `563948c93c3d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPHtmlPreferencesViewController.xib` | `3f36c0108c13` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPMarkdownPreferencesViewController.xib` | `bccab13b6980` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPTerminalPreferencesViewController.xib` | `b333323b7a06` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MainMenu.xib` | `731e44fa814a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/Localizable.strings` | `58b8f416a834` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPEditorPreferencesViewController.strings` | `6aac9b0dfe29` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPExportPanelAccessoryViewController.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPGeneralPreferencesViewController.strings` | `43c692936622` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPHtmlPreferencesViewController.strings` | `989c6f017fcb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPMarkdownPreferencesViewController.strings` | `ef08e1b174f1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPTerminalPreferencesViewController.strings` | `325b38fffd63` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MainMenu.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/Localizable.strings` | `35840357dc96` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPDocument.strings` | `77d13ae6ad6e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPEditorPreferencesViewController.strings` | `dc3422797b03` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPExportPanelAccessoryViewController.strings` | `5fa6411ea7a4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPGeneralPreferencesViewController.strings` | `4a7ed1f06701` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPHtmlPreferencesViewController.strings` | `f2756b964805` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPMarkdownPreferencesViewController.strings` | `9eecfa07f368` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPTerminalPreferencesViewController.strings` | `46f4777460e0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MainMenu.strings` | `74f8f5970a85` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/Localizable.strings` | `2dbb4e4b3246` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPDocument.strings` | `661f00f40ef8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPEditorPreferencesViewController.strings` | `4d8ab7b3681f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPExportPanelAccessoryViewController.strings` | `d10cd7f4e6d1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPGeneralPreferencesViewController.strings` | `df99276854c5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPHtmlPreferencesViewController.strings` | `50960a21e6da` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPMarkdownPreferencesViewController.strings` | `49ab2f6f01e1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPTerminalPreferencesViewController.strings` | `4f13ac0447fe` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MainMenu.strings` | `2ccc4edf04d6` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da.lproj/Localizable.strings` | `1fbe82793907` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da.lproj/MainMenu.strings` | `c4613839a041` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/Localizable.strings` | `0d5cbd7b1af8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPDocument.strings` | `77d13ae6ad6e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPEditorPreferencesViewController.strings` | `5e4bc020dc6c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPExportPanelAccessoryViewController.strings` | `aea0a2a42fdc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPGeneralPreferencesViewController.strings` | `43cba8a099c4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPHtmlPreferencesViewController.strings` | `c3c651a765c2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPMarkdownPreferencesViewController.strings` | `d88b529df666` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPTerminalPreferencesViewController.strings` | `c7b5147b9252` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MainMenu.strings` | `97bc3e9e956b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/en.lproj/InfoPlist.strings` | `feb5e820d68e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/en.lproj/Localizable.strings` | `6057a201b81b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/InfoPlist.strings` | `fdad9cd80416` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/Localizable.strings` | `3b735be9b95c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPDocument.strings` | `53eb91af71ef` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPEditorPreferencesViewController.strings` | `c1a23cfc7b62` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPExportPanelAccessoryViewController.strings` | `6788951d9b96` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPGeneralPreferencesViewController.strings` | `99d3d9bc434d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPHtmlPreferencesViewController.strings` | `05eb988cd145` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPMarkdownPreferencesViewController.strings` | `b743eaf4d82e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPTerminalPreferencesViewController.strings` | `4c38cc2049eb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MainMenu.strings` | `b129f49d084e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/Localizable.strings` | `90e8c7cefa00` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPEditorPreferencesViewController.strings` | `cec21748449d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPExportPanelAccessoryViewController.strings` | `9de83922c266` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPGeneralPreferencesViewController.strings` | `02c01df21a8e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPHtmlPreferencesViewController.strings` | `02ee634b4dbc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPMarkdownPreferencesViewController.strings` | `aaee9c6a2338` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPTerminalPreferencesViewController.strings` | `0e05dff823f1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MainMenu.strings` | `2fde783507f2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fi.lproj/Localizable.strings` | `cd4ff5028316` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fi.lproj/MainMenu.strings` | `42cc431675cd` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/Localizable.strings` | `8c639198363d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPDocument.strings` | `234472c13bdb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPEditorPreferencesViewController.strings` | `074001f98791` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPExportPanelAccessoryViewController.strings` | `3d81f3e467ff` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPGeneralPreferencesViewController.strings` | `7294e6b1dc39` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPHtmlPreferencesViewController.strings` | `2bb18bca6529` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPMarkdownPreferencesViewController.strings` | `b4a3d0e7abb0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPTerminalPreferencesViewController.strings` | `e7d7c0e2846a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MainMenu.strings` | `b07946ea0bb6` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/Localizable.strings` | `6a5207a8dd0f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPEditorPreferencesViewController.strings` | `434b042270cc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPGeneralPreferencesViewController.strings` | `8e742802f83b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPHtmlPreferencesViewController.strings` | `69dc3ebc9ea0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPMarkdownPreferencesViewController.strings` | `58e4bc22cc43` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPTerminalPreferencesViewController.strings` | `c2ce1c444126` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/Localizable.strings` | `055a28a0f519` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPEditorPreferencesViewController.strings` | `529860eabfe4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPGeneralPreferencesViewController.strings` | `951d58371c2e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPHtmlPreferencesViewController.strings` | `4d9b6c81ebc2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPMarkdownPreferencesViewController.strings` | `2d4ea129ce35` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPTerminalPreferencesViewController.strings` | `ad51fae53e4e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/Localizable.strings` | `7eeabc5a690d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPEditorPreferencesViewController.strings` | `693db64942fe` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPExportPanelAccessoryViewController.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPGeneralPreferencesViewController.strings` | `ceb6a0aa1d5b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPHtmlPreferencesViewController.strings` | `f74638f1665e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPMarkdownPreferencesViewController.strings` | `2cd40faf4d0d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPTerminalPreferencesViewController.strings` | `437f1a4c8014` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MainMenu.strings` | `c8268c3a1291` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/Localizable.strings` | `28a36e295db8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPEditorPreferencesViewController.strings` | `6c1e968da5b9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPExportPanelAccessoryViewController.strings` | `e30888d3a377` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPGeneralPreferencesViewController.strings` | `6b2ffed50489` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPHtmlPreferencesViewController.strings` | `51350dfa188f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPMarkdownPreferencesViewController.strings` | `6eaf2544d289` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPTerminalPreferencesViewController.strings` | `a8a413d427c5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MainMenu.strings` | `31b7dcf0e068` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/Localizable.strings` | `35aa3f26eab3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPDocument.strings` | `896e2e4d7fac` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPEditorPreferencesViewController.strings` | `c6579561c40a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPExportPanelAccessoryViewController.strings` | `f9ebfb561131` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPGeneralPreferencesViewController.strings` | `dc438ae1a2c5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPHtmlPreferencesViewController.strings` | `d21df1eb3fd0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPMarkdownPreferencesViewController.strings` | `230493eedbe2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPTerminalPreferencesViewController.strings` | `8d4d2b85ce5b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MainMenu.strings` | `7a8af1910a61` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/Localizable.strings` | `c50cc32c3a32` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPEditorPreferencesViewController.strings` | `40033238b028` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPExportPanelAccessoryViewController.strings` | `181aad75e3a8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPGeneralPreferencesViewController.strings` | `f53d0195b3b7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPHtmlPreferencesViewController.strings` | `dee78fab447e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPMarkdownPreferencesViewController.strings` | `a7bbb9ebcc72` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPTerminalPreferencesViewController.strings` | `bb080e8395f1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MainMenu.strings` | `6d5a5d0f2da2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/Localizable.strings` | `b10f98e62dbb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPDocument.strings` | `661f00f40ef8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPEditorPreferencesViewController.strings` | `f9f9d5e506ca` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPExportPanelAccessoryViewController.strings` | `cf22c1463bfd` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPGeneralPreferencesViewController.strings` | `9151212cec29` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPHtmlPreferencesViewController.strings` | `eb95fed65249` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPMarkdownPreferencesViewController.strings` | `818c9a671eed` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPTerminalPreferencesViewController.strings` | `4ec7982fd0a3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MainMenu.strings` | `3b57f5500508` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/InfoPlist.strings` | `fdad9cd80416` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/Localizable.strings` | `71cdfcefe8a2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPDocument.strings` | `b55fddad29cf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPEditorPreferencesViewController.strings` | `620bfb32c1a3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPExportPanelAccessoryViewController.strings` | `0852735a0254` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPGeneralPreferencesViewController.strings` | `7f5d6a8aa957` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPHtmlPreferencesViewController.strings` | `e5b853b2c193` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPMarkdownPreferencesViewController.strings` | `d371ceb26f10` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPTerminalPreferencesViewController.strings` | `f0a714e9ca27` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MainMenu.strings` | `cc08d6a1639d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/Localizable.strings` | `74c2946c2c19` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPDocument.strings` | `53eb91af71ef` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPEditorPreferencesViewController.strings` | `f3a47fdc4575` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPExportPanelAccessoryViewController.strings` | `f39dbd56254f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPGeneralPreferencesViewController.strings` | `a58ba2f5891f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPHtmlPreferencesViewController.strings` | `ac50e93130d7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPMarkdownPreferencesViewController.strings` | `53ffafc65477` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPTerminalPreferencesViewController.strings` | `7baaf07449b7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MainMenu.strings` | `ed748fd0d299` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/Localizable.strings` | `68868adca55e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPDocument.strings` | `ebb371a9af64` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPEditorPreferencesViewController.strings` | `8da93228df9f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPGeneralPreferencesViewController.strings` | `9507bf17c12e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPHtmlPreferencesViewController.strings` | `2fc7cb5b8135` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPMarkdownPreferencesViewController.strings` | `5410d9fe6a9e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPTerminalPreferencesViewController.strings` | `9f101611d38d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MainMenu.strings` | `d63e5ac90489` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/Localizable.strings` | `01fbebec2b10` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPEditorPreferencesViewController.strings` | `226be126c609` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPExportPanelAccessoryViewController.strings` | `a83d1f38e4ef` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPGeneralPreferencesViewController.strings` | `de39fe488104` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPHtmlPreferencesViewController.strings` | `0b382c7cba9b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPMarkdownPreferencesViewController.strings` | `6269d07eb1ee` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPTerminalPreferencesViewController.strings` | `21c9b90634f6` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MainMenu.strings` | `d0fbef74b1ff` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/Localizable.strings` | `ac3110a647b3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPDocument.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPEditorPreferencesViewController.strings` | `4bcee71f9638` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPExportPanelAccessoryViewController.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPGeneralPreferencesViewController.strings` | `5868c0063dae` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPHtmlPreferencesViewController.strings` | `cf8a0f88b969` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPMarkdownPreferencesViewController.strings` | `3348650987b1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPTerminalPreferencesViewController.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MainMenu.strings` | `c8d75d4fa5c9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/Localizable.strings` | `1c23dde183a1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPDocument.strings` | `815060511db9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPEditorPreferencesViewController.strings` | `4d1629c4844c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPExportPanelAccessoryViewController.strings` | `e3b0c44298fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPGeneralPreferencesViewController.strings` | `b9da4d2eef23` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPHtmlPreferencesViewController.strings` | `839a4a4f8130` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPMarkdownPreferencesViewController.strings` | `7160f2e607bc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPTerminalPreferencesViewController.strings` | `75772ca8eefa` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MainMenu.strings` | `fd018b1d2d6d` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/Localizable.strings` | `a84ff7f40dfe` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPEditorPreferencesViewController.strings` | `d80ab16b0651` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPGeneralPreferencesViewController.strings` | `3d55949247ea` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPHtmlPreferencesViewController.strings` | `7b4dffc8a972` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPMarkdownPreferencesViewController.strings` | `dd9a57ace594` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPTerminalPreferencesViewController.strings` | `657cdde9ca94` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/InfoPlist.strings` | `d5ba7085d8c5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/Localizable.strings` | `e015dfd4e881` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPDocument.strings` | `20660125f5e9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPEditorPreferencesViewController.strings` | `fbf96c9b3cc4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPExportPanelAccessoryViewController.strings` | `df1b425f1227` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPGeneralPreferencesViewController.strings` | `ae626a97ebb1` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPHtmlPreferencesViewController.strings` | `e86765eae530` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPMarkdownPreferencesViewController.strings` | `92bbcb070a3e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPTerminalPreferencesViewController.strings` | `52c00c7f1ab9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MainMenu.strings` | `6377fadaaf13` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/InfoPlist.strings` | `df0f8657ad22` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/Localizable.strings` | `a0b66aa86271` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPDocument.strings` | `cb70afa03af6` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPEditorPreferencesViewController.strings` | `5ae835b35318` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPExportPanelAccessoryViewController.strings` | `324816a8e6fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPGeneralPreferencesViewController.strings` | `bbe35625c028` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPHtmlPreferencesViewController.strings` | `518a4695f592` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPMarkdownPreferencesViewController.strings` | `d121df58ef10` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPTerminalPreferencesViewController.strings` | `1663464575c7` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MainMenu.strings` | `3454158535f0` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/MacDown-Info.plist` | `681500c51779` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/MacDown.entitlements` | `62eb40b798da` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Data/data.map` | `025a921e2605` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Data/treats.map` | `dba33b7668fc` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/export.css` | `401a13f7ec85` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/mermaid.forest.css` | `30f7a6778b2c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/mermaid.init.js` | `51e9477dfd47` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/print.css` | `da10026e3d91` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/show-information.css` | `b6264623da8f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/table-resize.js` | `bdd2edb6f2e2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/tasklist.js` | `baaec190711e` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Extensions/viz.init.js` | `4284c2771c20` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/MacDown.sdef` | `5643f7986c7f` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/MathJax/init.js` | `c1dba6dd3930` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Clearness Dark.css` | `f5e84a44a4eb` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Clearness.css` | `fc407d712394` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/GitHub Tomorrow.css` | `d274836c4802` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/GitHub-2020.css` | `8a193080ed45` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/GitHub.css` | `50b145c3b6ae` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/GitHub2.css` | `d526e3d22730` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Github2 (dark).css` | `d437fa41d152` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Gmail.css` | `cf2f35839c87` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Google Docs.css` | `7305f1bbf768` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Solarized (Dark).css` | `831c8a7c4159` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Styles/Solarized (Light).css` | `66385e7e1266` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Templates/Default.handlebars` | `3911974b1f3b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/GitHub Dark Default+.style` | `1c871c959cdd` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/GitHub Dark Default.style` | `7ddc20007c5b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Fresh Air+.style` | `9c7b5281bc57` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Fresh Air.style` | `7cf14e229256` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Night+.style` | `29ac097ec816` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Night.style` | `5f07cfb769df` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Paper+.style` | `8d2350b0042a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Mou Paper.style` | `f91490c350a9` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Solarized (Dark)+.style` | `2fc489c15373` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Solarized (Dark).style` | `b087429dda9c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Solarized (Light)+.style` | `807de1062aad` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Solarized (Light).style` | `1e62c3734ef4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Tomorrow Blue.style` | `090ad9ac160c` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Tomorrow+.style` | `ed759e275d7a` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Tomorrow.style` | `75c8dc06b2f4` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Writer+.style` | `732b282bb992` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/Themes/Writer.style` | `1f9c437258f2` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/syntax_highlighting.json` | `048275f9e5a6` | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Resources/updateHeaderLocations.js` | `e15be78acc0b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/Info.plist` | `9c444ac2cdac` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPMarkdownPreprocessor.h` | `ed5e8e88ac2b` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPQuickLookPreferences.h` | `26d4c0091d14` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPQuickLookPreferences.m` | `e269e6e827ef` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPQuickLookRenderer.h` | `8624df9faeb3` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPQuickLookRenderer.m` | `7c14e16770e5` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MacDownCore.h` | `903651853151` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownQuickLook/Info.plist` | `59e4ab4e6df8` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownQuickLook/MacDownQuickLook.entitlements` | `2c615c485eaf` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownQuickLook/PreviewViewController.h` | `638953029363` | ☐ | ☐ | ☐ | à lire | — |
| `MacDownQuickLook/PreviewViewController.m` | `6fad5f1905f4` | ☐ | ☐ | ☐ | à lire | — |
| `Podfile` | `285ad31ecf44` | ☐ | ☐ | ☐ | à lire | — |
| `Podfile.lock` | `9a421717ced1` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/.gitignore` | `ca1838cde9e4` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/Makefile` | `25ea97722bc0` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/index.sass` | `876e8f8a34a6` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/package-lock.json` | `e4e7fe566e70` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/package.json` | `c40a49e1291c` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/compat.py` | `113a769af85a` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/generate_version_header.sh` | `755b872263dc` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/macdown_utils.py` | `2f02ee26ef73` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/repro-stall.sh` | `a0ee310115f9` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/sign_sparkle.sh` | `63740bc01bd5` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/smoke_launch.sh` | `d8648538634c` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/update_build_number.sh` | `633982df9b4d` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/utils.sh` | `6fa173ed0679` | ☐ | ☐ | ☐ | à lire | — |
| `Tools/verify_sparkle_signature.sh` | `dbf1db97d46b` | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPArgumentProcessor.h` | `bcb98b7454a3` | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPArgumentProcessor.m` | `cb12a2c3d28b` | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPCommandInput.h` | `62aeaedd676d` | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPCommandQueue.h` | `4fa62af434ce` | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/main.m` | `daa47555cc8a` | ☐ | ☐ | ☐ | à lire | — |
| `scripts/regenerate-golden-files.sh` | `897f221ab3bb` | ☐ | ☐ | ☐ | à lire | — |
| `setup.sh` | `b6b594c02231` | ☐ | ☐ | ☐ | à lire | — |

## Parcours et invariants

À reconstruire depuis les sources actuelles : documents/IO/undo, rendu/export/PDF, navigation/sandbox, préférences/migrations, queue CLI, ressources/locales/éditeur, Quick Look, build/version/signature/mise à jour. Les différences légitimes et éventuels pipelines concurrents devront être établis sans reprendre les conclusions antérieures.

## Défauts et corrections

Aucun défaut nouvellement confirmé à l'initialisation. Identifiants A3-* ; un commit distinct par correction, tests de non-régression et relecture entière du fichier final. Git/index et tests Xcode/UI centralisés par root. Les données utilisateur et l'application installée ne servent pas de fixtures.

## Contrôles et critères de livraison

Lectures, analyses, secondes passes, tests ciblés, suites configurées, builds universels, consommateurs réels et réconciliation finale restent à exécuter pour cette campagne. Aucun résultat ancien n'est déclaré actuel. Les anciens vaults/helpers pourront inspirer une nouvelle isolation, après relecture et vérification de leurs chemins.

## Compteurs

482 fichiers actifs, 0 lu, 0 analysé, 0 validé. Les cases seront mises à jour uniquement après decisions manuelles justifiées.
