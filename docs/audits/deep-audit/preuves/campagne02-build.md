# Campagne 02 — build / CLI / PEG / YAML

Baseline : `e5a5c237b92d172e953abf0680869ad0a5b4806f`. Relecture neuve sans preuves antérieures. Lot actif en cours : aucun verdict global de validation.

## A2-B01 — provenance et versions des releases manuelles

Défaut confirmé. Le contrat documenté (`plans/release-process.md`, Manual Trigger) autorise une release sans tag préexistant. Le workflow initial construisait la ref choisie mais action-gh-release ne recevait pas `target_commitish` ; un nouveau tag pouvait donc désigner la branche par défaut. Une version/tag existant pouvait aussi recevoir un binaire issu d'un autre HEAD. Le header CLI provenait de git describe, divergent d'Info.plist explicitement versionné.

Correction cohérente : un seul contrôle d'ascendance main/release pour les deux entrées ; refus d'un tag existant différent de HEAD ; RELEASE_COMMIT/RELEASE_TAG capturés et transmis à action-gh-release ; paire de version/build transmise au générateur des constantes CLI, validée avant écriture. Développement sans override conserve le contrat git.

Régression ajoutée : `python3 MacDownTests/BuildTools/release_identity_tests.py`, vrais dépôts Git temporaires et clang/C consommateur du header. Phase rouge exécutée sur source avant modification : exit 1, variables produites seulement `{VERSION: 2.0.0-rc.1}`, absence RELEASE_TAG/COMMIT. Phase verte : exit 0, nouvelles releases release-branch ancrées, tag existant autre HEAD refusé, auto-détection autre HEAD refusée, tag et rebuild même commit admis, branche hors main/release refusée, header C consommé comme `2.0.0-rc.1` / `873`, overrides incomplets/non numériques/malformés refusés sans altérer header.

Contrôles voisins exécutés : `python3 MacDownTests/BuildTools/version_tests.py` exit 0 ; `python3 MacDownTests/BuildTools/packaging_version_tests.py` exit 0. Aucun Xcode ni service externe exercé. La conformité de l'archive Xcode complète et publication GitHub/notarisation restent à vérifier par root/CI ; les tests n'appellent aucun service ou Git du dépôt partagé.

Relecture finale complète : release.yml en plages 1–280 / 281–560 / 561–fin ; action.yml/test.yml/generate_version_header.sh et test nouveau en entier. Interactions : legacy version target passBuildSettingsInEnvironment=1, Makefile FORCE ; MPArgumentProcessor imprime les constantes du header ; Info.plist reçoit MARKETING_VERSION/CURRENT_PROJECT_VERSION.

SHA-256 état final relu (à invalider si autre correction change le chemin) :

- `.github/workflows/release.yml` : `f44f74aa3636d750386fcee0bcecfa1fe996fa5544fc641d597ccf27228e9653`
- `.github/actions/build-macdown/action.yml` : `b8c590e20b14a14a0473d0a864906a33edc16b155d36a7708bd32901c38539e4`
- `Tools/generate_version_header.sh` : `755b872263dc52613c528b7f7c8936e51a9ee52981bed081e5c0ecaecf7709dc`
- `.github/workflows/test.yml` : `8edb40441281c15ce48f6ba2919566b702832a90480ab0353f451f4c41bad200`
- `MacDownTests/BuildTools/release_identity_tests.py` : `8698f2f5042140178c18f6bd04dcf30dc01cd1f8f16da8e3ba40b7d09ea2dbe5`

Source primaire vérifiée A2-B01 : [action-gh-release v1 README, target_commitish](https://raw.githubusercontent.com/softprops/action-gh-release/v1/README.md), option commit/branch et branche défaut en absence d’option.

## A2-B02 — amplification et profondeur des graphes YAML

Défaut confirmé sur la pile réelle compilée standalone : YAMLSerialization.m/M13OrderedDictionary (ARC)/LibYAML locaux, Foundation ; aucune préférence ni Xcode. Graphe acyclique 219 caractères/10 niveaux → description 325650 caractères ; 311/14 → 7307282 ; 403/18 → 150470674. Le consommateur atteignable MPDocument.presumedFileName utilise `[frontMatter[title] description]` à la sauvegarde d'un nouveau document lorsque la détection front matter est activée. L'ancienne validation mémorisait seulement « déjà acyclique » et ne bornait ni coût d'alias ni hauteur réelle après réutilisation. Le chemin HTMLTable récursif existe mais le pipeline preview courant ne le consomme pas : il ne sert pas de preuve d'atteignabilité.

Correction source unique : validation du graphe avant Foundation ; métriques mémoïsées (hauteur, nœuds développés, octets scalaires), coûts additionnés par référence. Plafonds défensifs explicités : profondeur 256 (contrat antérieur), 100000 nœuds développés, 16MiB scalaires développés, addition précédée de soustraction pour éviter débordement. Les alias ordinaires et contrats de containers/keys sont conservés. L'erreur `kYAMLErrorInvalidYamlObject` permet à NSString.frontMatter de retourner nil selon son contrat actuel. Budget fixe intentionnel : front matter dépassant ces bornes est désormais refusé, même s'il est syntaxiquement valide.

Régression `python3 MacDownTests/BuildTools/yaml_graph_tests.py` compile la source entière, M13OrderedDictionary et tous les fichiers C LibYAML avec son config.h réel, dans TemporaryDirectory. Rouge exécuté avant correction : exit1 « Amplifying front matter must be rejected before title description allocation ». Vert exit0 : amplification18 refusée avant description ; alias modéré accepté et description consommée ; cycles refusés ; chaîne260 traversant des alias précédemment mémoïsés refusée ; scalar64KiB repris300 fois refusé ; clé collection lookup et mutable containers préservés. Gate ajoutée à test.yml. Relecture finale YAMLSerialization.m entière 1–310/311–fin, test .m/.py et workflow entier. Limite : UI sauvegarde/XCTest complet confiés à root ; standalone vérifie composant réel et expression du consommateur, pas le dialogue de sauvegarde.

## A2-B03 — demandes CLI écrasées avant consommation

Reproduction exécutée en processus Foundation distincts, catégorie NSUserDefaults+Suite.m réelle et fonctions MPCollectForMacDown extraites sans modification de main.m, suite CFPreferences `app.macdown.audit-UUID` dédiée puis nettoyée. Producteur alpha, producteur beta, lecteur : seul beta subsiste. Lecteur snapshot alpha, producteur beta, effacement de la clé par le consommateur : état null, beta perdue. Aucun accès à la suite utilisateur MacDown. Cette séquence interprocess établit les deux fenêtres de perte ; ce n'est pas un stress aléatoire ni une preuve d'ouverture UI. Correction de protocole producteur+consumer nécessaire, coordonnée avec root ; aucune modification consumer hors lot sans accord.

## Lecture complète et exclusion requalifiée

70 fichiers du lot relus intégralement pendant cette campagne. project.pbxproj principal (2909 lignes) : lecture d'une copie temporaire où chaque GUID24hex est remplacé bijectivement par REF1…REF688 ; aucune autre transformation, commentaires/champs/ordre conservés, toutes plages tronquées relues. Les GUID sont des identités opaques ; références concordantes restent identiques et reliées. Analyse du graphe de targets, dépendances ressources/version/PEG, phases copie/signature, configurations Debug/Release et schemes. Cette lecture ne prouve pas l'exécution Xcode.

`greg/greg.c` n'est pas exclu comme généré : le Makefile le compile pour bootstrap du générateur lui-même. Relecture intégrale runtime/actions/grammaire/main et comparaison au contrat greg.g/compile.c/tree.c. Les tiers embarqués YAML/PEG sont actifs et restent inclus. pmh_parser.c/core.c non suivis générés à partir head/grammar/foot sont consommateurs consultables ; génération/compilation temp exécutée avec UBSan via peg_contracts.py (exit0). Aucun historique d'audit utilisé.
