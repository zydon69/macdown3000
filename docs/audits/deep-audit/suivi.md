# Deep audit — campagne 02, départ de zéro

Statut : **en cours, non prêt à livrer**. Début : 2026-10-07. Révision source : `e5a5c237b92d172e953abf0680869ad0a5b4806f`. Arbre initial propre. Ancien audit archivé dans [historique/campagne-01-e5a5c23](historique/campagne-01-e5a5c23/suivi.md) ; ses cases/preuves ne valident aucun fichier de cette nouvelle campagne.

## Périmètre et méthode

Projet MacDown, Objective-C/C, AppKit/WebKit, JavaScript, Xcode/CocoaPods. Aucun dossier app/database Laravel : même application et outils associés que le périmètre accepté précédemment, réinventoriés physiquement depuis la racine. Chaque fichier sera entièrement relu et réanalysé. Empreintes de découverte uniquement dans JSON ; aucune preuve de lecture déduite d'un hash ou d'un test. Exclusions réexaminées par leur propriétaire. Corrections certaines, tests métier et un commit par correction ; Git/index et Xcode centralisés par root. Pas de push implicite de cette campagne.

| Lot | Fonction | Fichiers |
| --- | --- | --- |
| root-document | Fichiers attribués dans lots/root-document.json, lecture des dépendances autorisée | 45 |
| build-cli-peg | Fichiers attribués dans lots/build-cli-peg.json, lecture des dépendances autorisée | 70 |
| ui-locales | Fichiers attribués dans lots/ui-locales.json, lecture des dépendances autorisée | 304 |
| rendering-pdf-quicklook | Fichiers attribués dans lots/rendering-pdf-quicklook.json, lecture des dépendances autorisée | 60 |

## Exclusions de racines

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

| Chemin | SHA-256 effectivement analysé | Lu | Analysé | Validé | État / points ouverts | Preuves |
| --- | --- | --- | --- | --- | --- | --- |
| `.envrc.example` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/actions/build-macdown/action.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/actions/setup-macdown/action.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/dependabot.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/build-release.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/markdownlint.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/release.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/smoke-test.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/staple-release.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/test.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.github/workflows/update-website.yml` | — | ☐ | ☐ | ☐ | à lire | — |
| `.gitignore` | — | ☐ | ☐ | ☐ | à lire | — |
| `.gitmodules` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/YAML-framework/YAMLSerialization.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/YAML-framework/YAMLSerialization.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlighter.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlighter.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlightingStyle.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/HGMarkdownHighlightingStyle.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/Makefile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/Makefile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/compile.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.g` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/greg.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/greg/tree.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/peg-markdown-highlight.xcodeproj/project.pbxproj` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/peg-markdown-highlight.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_definitions.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_grammar.leg` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser_foot.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_parser_head.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_styleparser.c` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/pmh_styleparser.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/peg-markdown-highlight/tools/combine_parser_files.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/version/Makefile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Dependency/version/version.xcodeproj/project.pbxproj` | — | ☐ | ☐ | ☐ | à lire | — |
| `Gemfile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Gemfile.lock` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/project.pbxproj` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/xcshareddata/xcschemes/MacDown.xcscheme` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcodeproj/xcshareddata/xcschemes/MacDownUITests.xcscheme` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/contents.xcworkspacedata` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown 3000.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPExportPanelAccessoryViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPExportPanelAccessoryViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPMainController.h` | `243032702a66` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Application/MPMainController.m` | `fee700c0ec78` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Application/MPToolbarController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Application/MPToolbarController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Document/MPAsset.h` | `c1a03ae5c84d` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Document/MPAsset.m` | `a4e260bd0ab2` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Document/MPDocument.h` | `f70d0155da47` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Document/MPDocument.m` | `a6623063fc81` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Document/MPPDFAnchorInjector.h` | `7dbaa29df89e` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Document/MPPDFAnchorInjector.m` | `902c57b2cb63` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Document/MPRenderer.h` | `45e93c4fd1c0` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Document/MPRenderer.m` | `a939696a43b8` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Extension/DOMNode+Text.h` | `748eb6ded390` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/DOMNode+Text.m` | `4005d622d14d` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSColor+HTML.h` | `ed1b5feb51f0` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSColor+HTML.m` | `c97b507bf33b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSDocumentController+Document.h` | `502d752bb8dc` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSDocumentController+Document.m` | `4af8a68681d5` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSJSONSerialization+File.h` | `93948eae8346` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSJSONSerialization+File.m` | `2408f3ab942a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSObject+HTMLTabularize.h` | `1849ce0e2b22` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSObject+HTMLTabularize.m` | `1d87c68ca646` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSPasteboard+Types.h` | `6d27da2a53fa` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSPasteboard+Types.m` | `d61025bbf8f5` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSString+Lookup.h` | `8fcb13267c19` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSString+Lookup.m` | `9e18ee26f0cf` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSTextView+Autocomplete.h` | `ea69f917e5a7` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSTextView+Autocomplete.m` | `948afe284ee3` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSUserDefaults+Suite.h` | `cac0f676b540` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/NSUserDefaults+Suite.m` | `e0b928949e2a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/WebView+WebViewPrivateHeaders.h` | `f537f69c38a0` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Extension/hoedown_html_patch.c` | `40ac164f2e75` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/Extension/hoedown_html_patch.h` | `763870f5ef85` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Code/MacDown-Prefix.pch` | `d68c3773ffcf` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Preferences/MPEditorPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPEditorPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPGeneralPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPGeneralPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPHtmlPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPHtmlPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPMarkdownPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPMarkdownPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferences.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferences.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPTerminalPreferencesViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Preferences/MPTerminalPreferencesViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFileNode.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFileNode.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderSidebarViewController.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderSidebarViewController.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderWatcher.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPFolderWatcher.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSplitView.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSplitView.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSyncCoordinator.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Sidebar/MPSidebarSyncCoordinator.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/Utility/FileURLInlining.h` | `c1696072c1ee` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/FileURLInlining.m` | `8b6cab69f85d` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPAutosaving.h` | `798fb7bd3f3a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPFileWatcher.h` | `07689eb11b45` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPFileWatcher.m` | `ee5059ab5cd7` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPGlobals.h` | `8ed8632ca58c` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPHTMLResourceURLs.h` | `59696bfe884e` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPHTMLResourceURLs.m` | `ead2d9ccec8a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPHomebrewSubprocessController.h` | `eb1e9070b3fe` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPHomebrewSubprocessController.m` | `0e7450785408` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPMathJaxListener.h` | `91ae4785b093` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPMathJaxListener.m` | `818553ca0a3a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPResourceWatcherSet.h` | `db6f55e8e1ba` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPResourceWatcherSet.m` | `d4663a4990d8` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPURLSecurityPolicy.h` | `cff58c6ee4f0` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPURLSecurityPolicy.m` | `ae6111380d3d` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPUtilities.h` | `583fb5ceb495` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/Utility/MPUtilities.m` | `3e05f9cc43cf` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Code/View/MPDocumentSplitView.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPDocumentSplitView.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPEditorView.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/View/MPEditorView.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Code/main.m` | `d806c4913d7b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Images.xcassets/AppIcon.appiconset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesEditor.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesGeneral.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesMarkdown.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesRendering.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Preferences Icons/PreferencesTerminal.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconBlockquote.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconBold.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconComment.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconCopyHTML.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconEditorAndPreview.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading1.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading2.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHeading3.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHideEditor.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHidePreview.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconHighlight.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconImage.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconInlineCode.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconItalic.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconLink.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconOrderedList.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconShiftLeft.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconShiftRight.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconStrikethrough.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconUnderlined.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/Toolbar Icons/ToolbarIconUnorderedList.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconBlockquote.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconComment.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconCopyHTML.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconEditorAndPreview.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHeadings.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHideEditor.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHidePreview.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconHighlight.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconImage.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconInlineCode.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconLink.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconOrderedList.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconShiftLeft.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconShiftRight.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconStrikethrough.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Images.xcassets/TouchBar Icons/TouchBarIconUnorderedList.imageset/Contents.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPDocument.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPEditorPreferencesViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPExportPanelAccessoryViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPGeneralPreferencesViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPHtmlPreferencesViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPMarkdownPreferencesViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MPTerminalPreferencesViewController.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/Base.lproj/MainMenu.xib` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ar.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/cs.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da-DK.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/da.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/de.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/en.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/en.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/es.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/et.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fi.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fi.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/fr.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/he.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/hi.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/is.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/it-IT.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ja.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ko-KR.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nb-NO.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/nl-NL.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/pt-BR.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/ru-RU.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sk.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/sv.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/tr.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/uk.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hans.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/InfoPlist.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/Localizable.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPDocument.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPEditorPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPExportPanelAccessoryViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPGeneralPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPHtmlPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPMarkdownPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MPTerminalPreferencesViewController.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/Localization/zh-Hant.lproj/MainMenu.strings` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDown/MacDown-Info.plist` | `681500c51779` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/MacDown.entitlements` | `62eb40b798da` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-root.md |
| `MacDown/Resources/Extensions/export.css` | `401a13f7ec85` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/mermaid.forest.css` | `30f7a6778b2c` | ☑ | ☑ | ☑ | validé | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/mermaid.init.js` | `51e9477dfd47` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/print.css` | `da10026e3d91` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/show-information.css` | `b6264623da8f` | ☑ | ☑ | ☑ | validé | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/table-resize.js` | `bdd2edb6f2e2` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/tasklist.js` | `baaec190711e` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Extensions/viz.init.js` | `4284c2771c20` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/MacDown.sdef` | `5643f7986c7f` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/MathJax/init.js` | `c1dba6dd3930` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Clearness Dark.css` | `f5e84a44a4eb` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Clearness.css` | `fc407d712394` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/GitHub Tomorrow.css` | `d274836c4802` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/GitHub-2020.css` | `8a193080ed45` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/GitHub.css` | `50b145c3b6ae` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/GitHub2.css` | `d526e3d22730` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Github2 (dark).css` | `d437fa41d152` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Gmail.css` | `cf2f35839c87` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Google Docs.css` | `7305f1bbf768` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Solarized (Dark).css` | `831c8a7c4159` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Styles/Solarized (Light).css` | `66385e7e1266` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Templates/Default.handlebars` | `3911974b1f3b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/GitHub Dark Default+.style` | `1c871c959cdd` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/GitHub Dark Default.style` | `7ddc20007c5b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Fresh Air+.style` | `9c7b5281bc57` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Fresh Air.style` | `7cf14e229256` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Night+.style` | `29ac097ec816` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Night.style` | `5f07cfb769df` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Paper+.style` | `8d2350b0042a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Mou Paper.style` | `f91490c350a9` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Solarized (Dark)+.style` | `2fc489c15373` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Solarized (Dark).style` | `b087429dda9c` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Solarized (Light)+.style` | `807de1062aad` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Solarized (Light).style` | `1e62c3734ef4` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Tomorrow Blue.style` | `090ad9ac160c` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Tomorrow+.style` | `ed759e275d7a` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Tomorrow.style` | `75c8dc06b2f4` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Writer+.style` | `732b282bb992` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/Themes/Writer.style` | `1f9c437258f2` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/syntax_highlighting.json` | `048275f9e5a6` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDown/Resources/updateHeaderLocations.js` | `e15be78acc0b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/Info.plist` | `9c444ac2cdac` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/MPQuickLookPreferences.h` | `26d4c0091d14` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/MPQuickLookPreferences.m` | `e269e6e827ef` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/MPQuickLookRenderer.h` | `8624df9faeb3` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/MPQuickLookRenderer.m` | `7c14e16770e5` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownCore/MacDownCore.h` | `903651853151` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownQuickLook/Info.plist` | `59e4ab4e6df8` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownQuickLook/MacDownQuickLook.entitlements` | `2c615c485eaf` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownQuickLook/PreviewViewController.h` | `638953029363` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `MacDownQuickLook/PreviewViewController.m` | `6fad5f1905f4` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `Podfile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Podfile.lock` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/.gitignore` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/Makefile` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/index.sass` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/package-lock.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/GitHub-style-generator/package.json` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/compat.py` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/generate_version_header.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/macdown_utils.py` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/repro-stall.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/sign_sparkle.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/smoke_launch.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/update_build_number.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/utils.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `Tools/verify_sparkle_signature.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPArgumentProcessor.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/MPArgumentProcessor.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `macdown-cmd/main.m` | — | ☐ | ☐ | ☐ | à lire | — |
| `scripts/regenerate-golden-files.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `setup.sh` | — | ☐ | ☐ | ☐ | à lire | — |
| `MacDownCore/MPMarkdownPreprocessor.h` | `ed5e8e88ac2b` | ☑ | ☑ | ☐ | à vérifier | preuves/campagne02-render.md |
| `macdown-cmd/MPCommandInput.h` | — | ☐ | ☐ | ☐ | à lire | — |
| `.markdownlint.json` | — | ☐ | ☐ | ☐ | à lire | — |

## Parcours et invariants

Carte à reconstruire depuis les entrées et leurs consommateurs. Fichiers de sauvegarde/rechargement, rendu/exports, navigation/clipboard, préférences/migration, dossiers/CLI, Quick Look et build/mises à jour examinés de bout en bout. Aucun flux actuellement validé.

## Findings, corrections et contrôles

Registre initial vide. Aucun résultat historique repris comme résultat exécuté de campagne02. Chaque finding aura un ID A2-xx, preuve, correction/test et état ; limites de test explicites.

## Critères de livraison

Tous ouverts : relecture/analyse intégrale, corrections confirmées et tests, consommateurs et seconde passe, suites/build/UI applicables, absence de pipelines divergents, réconciliation finale.

## Compteurs

479 fichiers actifs ; 0 lus, 0 analysés, 0 validés.
