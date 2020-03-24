# Suivi Flore Territoire

Module GeoNature du protocole Suivi flore territoire du réseau Flore Sentinelle, piloté par le CBNA. 

![SFT module](http://geonature.fr/docs/img/2018-09-sft.jpg)

**Démonstration vidéo** : 

![SFT démo](http://geonature.fr/docs/img/2019-01-geonature-sft-demo.gif)

A partir de Zones de Prospection (ZP) prospectées dans le protocole d'inventaire répété Bilan Stationnel (ex-Flore prioritaire), 
des ZP sont selectionnées pour faire office d'un suivi. Sur chacune de ces ZP, une espèce est prospectée régulièrement par mailles de 25m et l'absence ou la présence de l'espèce est renseignée pour chaque maille.

**Présentation** :

* Rapport de stage de Khanh-Chau Nguyen : http://geonature.fr/documents/2018-09-Nguyen-Khanh-Chau-Rapport-stage-M2DCISS.pdf
* Présentation de soutenance de stage de Khanh-Chau Nguyen : http://geonature.fr/documents/2018-09-Nguyen-Khanh-Chau-Soutenance-stage-M2DCISS.pdf

Installation
============

* Installez GeoNature (https://github.com/PnX-SI/GeoNature)
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_suivi_flore_territoire/archive/X.Y.Z.zip``) 
dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Créez et adaptez le fichier ``config/settings.ini`` à partir de ``config/settings.sample.ini`` :
  * Commande pour copier le fichier : ``cp config/settings.sample.ini config/settings.ini``
  * Si vous utilisez les données d'exemple, assurez vous d'avoir [intégrer le MNT (DEM) dans GeoNature](https://geonature.readthedocs.io/fr/latest/admin-manual.html#integrer-des-donnees)
* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes suivantes (le nom du module abrégé en "sft" est utilisé comme code) :

```
    source venv/bin/activate 
    geonature install_gn_module <mon_chemin_absolu_vers_le_module> /sft`` 
    # Exemple ``geonature install_gn_module /home/`whoami`/gn_module_suivi_flore_territoire-X.Y.Z /sft``)
```

* Réaliser les imports nécessaires au fonctionnement du module à l'aide des scripts disponibles :
  * les mailles (par défaut 25x25m) correspondant à vos sites ou à l'ensemble de la zone d'étude (si elle est de taille réduite) (`import_meshes.sh`)
  * les valeurs pour la nomenclature "Perturbation" (`import_nomenclature.sh`)
  * les taxons suivis (`import_taxonomy.sh`)
  * les sites (`import_sites.sh`)
* Les scripts d'imports possèdent tous :
  * des paramètres configurables dans le fichier `config/settings.ini`
  * une option `-h` permettant d'afficher leur aide
  * une option `-d` permettant de supprimer les données importées
* Complétez la configuration du module dans le fichier ``config/conf_gn_module.toml`` en surcouchant les valeurs 
par défaut présentes dans le fichier ``config/conf_gn_module.sample.toml``:
  * Commande pour copier le fichier par défaut : ``cp config/conf_gn_module.sample.toml config/conf_gn_module.toml`` 
  * Remplacer, si nécessaire, les identifiants des listes en les récupérant dans la base de données pour : `id_type_maille`, `id_type_commune`, `id_menu_list_user`, `id_list_taxon`
  * Ensuite, relancez la mise à jour de la configuration de GeoNature :
    * Se rendre dans le répertoire ``geonature/backend``
    * Activer le venv : ``source venv/bin/activate``
    * Lancer la commande de mise à jour de configuration du module (abrégé ici en "sft")  : ``geonature update_module_configuration sft``
* Vous pouvez sortir du venv en lançant la commande ``deactivate``

Désinstallation
===============
* Utiliser le script `bin/uninstall_db.sh` en vous plaçant dans le dossier bin puis en éxecutant : `./uninstall_db.sh`
* Cette action va supprimer toutes les données et structures en lien avec le module SFT dans la base de données.
* Vous pouvez ensuite supprimer le lien symbolique dans le dossier ``geonature/external_modules/``

Licence
=======

* [Licence OpenSource GPL v3](./LICENSE)
* Copyleft 2020 - Parc National des Écrins - Conservatoire National Botanique Alpin

[![Logo PNE](http://geonature.fr/img/logo-pne.jpg)](http://www.ecrins-parcnational.fr)

[![Logo CBNA](http://www.cbn-alpin.fr/images/stories/habillage/logo-cbna.jpg)](http://www.cbn-alpin.fr) 
