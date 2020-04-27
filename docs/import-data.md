# Importer des données dans Suivi Flore Territoire

Plusieurs script sont disponibles pour importer les données suivantes :
 - taxons (`import_taxons.sh`)
 - nomenclatures (`import_nomenclatures.sh`)
 - mailles (`import_meshes.sh`)
 - sites (`import_sites.sh`)
 - visites (`import_visits.sh`)

## Options des scripts d'import

Chacun de ces scripts est disponibles dans le dossier `bin/`. Il possèdent tous les options suivantes :
 - `-h` (`--help`) : pour afficher l'aide du script.
 - `-v` (`--verbosity`) : le script devient verbeux est affiche plus de messages concernant le travail qu'il accomplit.
 - `-x` (`--debug`) : le mode débogage de Bash est activé.
 - `-c` (--config) : permet d'indiquer le chemin vers un fichier de configuration spécifique. Par défaut, c'est le fichier `config/settings.ini` qui est utilisé.
 - `-d` (`--delete`) : chacun des imports peut être annulé avec option. Attention, il faut s'assurer que le script est correctement configuré avec les paramètres correspondant à l'import que vous souhaitez annuler.

## Procédure

Avant de lancer les scripts, il est nécessaires de correctement les paramètrer à l'aide du fichier `config/settings.ini`. Une section de paramètres concerne chacun d'entre eux.

Afin que les triggers présents sur les tables soient déclenchés dans le bon ordre et que les scripts trouvent bien les données de référence dont ils ont besoin, il est conseillé de réaliser les imports dans cet ordre :
 1. taxons
 2. nomenclatures
 3. mailles
 4. sites
 5. visites

Une fois l'ensemble des imports réalisés vous pouvez vérifier les données présentent dans la base à l'aide de l'interface du module mais aussi via le script `import_checks.sh`.
