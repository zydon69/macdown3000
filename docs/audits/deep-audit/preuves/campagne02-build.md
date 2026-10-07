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
