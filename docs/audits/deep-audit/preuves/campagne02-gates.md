# Gates exécutées sur les sources de campagne 02

État du 7 octobre 2026 après les neuf commits de correction et les nouvelles gates CI. Aucun résultat de campagne 01 ne remplace les exécutions ci-dessous.

| Contrôle réel | Résultat actuel | Preuve |
| --- | --- | --- |
| XCTest ciblés consommateur CLI | 7 tests, 0 échec | /tmp/macdown-campaign02-command-tests.log |
| XCTest complets | 1431 tests, 0 échec | /tmp/macdown-campaign02-full-tests.log |
| XCUITest launch/editor/frappe/présence preview | 4 tests, 0 échec | /tmp/macdown-campaign02-ui-tests.log |
| Debug universel | Build réussi ; sources finales arm64/x86_64 | /tmp/macdown-campaign02-debug-universal-build.log |
| Release universel | Build réussi ; app, CLI et extension arm64/x86_64 | /tmp/macdown-campaign02-release-build.log |
| Versions réellement embarquées Release | App/extension/CLI : 3000.0.7-rc.1.post183, build1594 | Info.plist de build/AuditCampaign02 + CLI --version |
| Six nouvelles régressions et deux runners JavaScript | Tous codes retour 0 | /tmp/macdown-campaign02-regressions.log |
| Huit runners scripts/empty-suite/version/release/packaging/PEG/YAML/print colors | Tous codes retour 0 | /tmp/macdown-campaign02-build-contracts.log |
| Sandbox préférences UUID | Lecture autorisée/refusée et écriture refusée | /tmp/macdown-campaign02-sandbox-preferences.log |
| Sandbox assets UUID | USER/BUNDLE fallback et périmètre lecture/écriture vérifiés | /tmp/macdown-campaign02-sandbox-assets.log |
| PDF natif avec constantes JS extraites des sources actuelles | Deux impressions réussies, destination interne résolue, pixels originaux capturés avant toute mutation identiques au résultat persisté, DOM/CSSOM restaurés | /var/folders/sl/qh_kc_kn1r732kw2tsj7z5xh0000gn/T/macdown-campaign02-native-pdf-strict-u06tm06z/report.json |
| Markdown lint configuré | Réussite sur les cinq documents configurés | /tmp/macdown-campaign02-markdownlint.log |
| Bundle UI/locales | 217 tables, 5184 clés, 0 erreur ; 8 nibs et 43 assets attendus | campagne02-ui-bundle.json / campagne02-ui-assets.json |

XCTest/XCUITest ont été exécutés dans un vault privé : domaines CF sauvegardés, ApplicationSupport/cache/savedState et pending CLI protégés, fixture HOME, restauration finale et égalité des préférences vérifiée. Les logs confirment des tests réellement exécutés. Les quatre UI tests ne prouvent pas chaque branche ou chaque langue ; les décisions UI par fichier prennent aussi en compte les lectures intégrales, contrats, tests AppKit ciblés et ressources compilées.

Le consommateur PDF natif compile le MPPDFAnchorInjector actuel et utilise les deux constantes de préparation/snapshot extraites du MPDocument actuel. WebView, NSPrintOperation et PDFKit sont réels ; le document HTML/CSS est une fixture déterministe. Il vérifie les contrats de transformation, impression, résolution et persistance, sans présenter cette fixture comme un parcours complet de menu export dans l'application.

## Consommation Quick Look et limites

Quick Look natif : gate visuelle réussie avec le host `/tmp/macdown-ql-native-apprun.m` utilisant `NSApplication.run`. Capture compositeur réelle inspectée par le réviseur : titre, paragraphe gras, bloc code avec fond et tableau avec bordures visibles. Rapport : `/private/var/folders/sl/qh_kc_kn1r732kw2tsj7z5xh0000gn/T/macdown-native-ql-surface-0ykmj1ay/report.json`, image `compositor-12s.png`, fenêtre 17045. Provider UUID sélectionné et PID 19963 observé avec chemin exact de l'extension clonée du Debug actuel ; host code retour 0, fenêtre active/key/visible, occlusion8194. Aucun binaire de diagnostic substitué. Le champ automatique `paintValidated:false` décrit la décision laissée au réviseur ; l'inspection visuelle manuelle ci-dessus apporte cette décision. Les premiers probes bitmap/manuelle NSRunLoop restaient noirs/vides faute de boucle AppKit complète ; ils ne démontrent pas un défaut applicatif.

Le probe termine avec code 2 uniquement parce que macOS protège des métadonnées du conteneur UUID : ce résultat de nettoyage est distingué du succès de consommation visuelle. Élection UUID remise à default, extension retirée et host désenregistré ; interrogation finale PlugInKit vide. Les preuves n'étendent pas le résultat à une distribution Developer ID ni aux préférences partagées, exercées séparément sous sandbox.

Les providers temporaires UUID ont été retirés des registres PlugInKit/LaunchServices. macOS protège les métadonnées de leurs conteneurs : ces seuls résidus de fixtures sont signalés dans les rapports et ne sont pas supprimés en modifiant les permissions système. Les domaines et assets utilisateur n'ont pas été utilisés dans ces probes sandbox.

L'essai exploratoire PEG ASan+UBSan expire pendant la génération instrumentée sans rapport mémoire ; UBSan et les tests de contrats actuels passent. ASan n'est pas déclaré validé. Une signature Developer ID, une notarisation ou une publication réelle ne sont pas réalisées par cet audit ; la distribution externe n'est pas certifiée par un build local réussi.

Contrat restant en analyse : code clair sur fond clair dans Quick Look avec thème par défaut Tomorrow. Le sélecteur Prism attend une classe language-* sur PRE, ajoutée normalement par son JavaScript ; Quick Look désactive ces scripts. La réussite de peinture ci-dessus ne certifie pas ce contraste ; reproduction computed-style et correction de la cause en cours. Les cinq adapters/terminologie supplémentaires sont également vérifiés avant la clôture du lot rendu.
