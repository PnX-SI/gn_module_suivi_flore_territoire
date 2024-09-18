# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier en français.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Inédit]


## [1.2.0] - 2024-08-20

### 🚀 Ajouté

- Compatible GeoNature 2.14
- Declaration des permissions CRUVED du module dans une branche Alembic. Les droits sont les mêmes pour les visites et observations
- Ajout des paramètres `meshes_source`, `site_code_column` et `site_desc_column` dans `bin/config/imports_settings.sample.ini`
- Ajout de la gestion de la date de fin des visites à l'interface (fiche détaillée et formulaire de saisie d'une visite)

### 🔄 Modifié

- Mise à jour du `README.md` et `install.md`
- Les paramètres `dataset_id` et `observers_list_id` dans `settings.ini` deviennent respectivement `id_dataset` et `id_menu_list_user` dans `conf_gn_module.toml` (voir `config/conf_gn_module.sample.toml` pour les valeurs par défaut)
- Les fonctions `check_user_cruved_visit` et `cruved_scope_for_user_in_module` sont remplacées par la classe `VisitAuthMixin` contenant des méthodes qui permettent de récupérer les droits des utilisateurs sur les données (action CRUVED + portée)
- La liste des visites d'un site affiche maintenant la date de fin de visite si au moins une des visites possède une date de fin de visite différente de sa date de début de visite.
- Une visite peut maintenant avoir lieu sur plusieurs années
- ⚠️ La vue `pr_monitoring_flora_territory.export_visits` a été corrigé afin d'exporter la date de fin de visite. Nous n'avons pas utilisé de révision Alembic pour la mise à jour. Il est nécessaire de mettre à jour cette vue manuellement à l'aide de Psql par exemple. Voir le code SQL de la vue dans le fichier [schema.sql](backend/gn_module_monitoring_flora_territory/migrations/data/schema.sql).


## [1.1.2] - 2022-11-30

### 🔄 Modifié

- La vérification du CRUVED est maintenant réalisé au niveau de tous les web services.
- Renommage de tous les composants du frontend pour clarifier leur utilisation. Utilisation du préfixe "mft", abréviation de "Monitoring Flora Territory".
- Les routes du module sont maintenant dans un fichier à part.
- Rassemblement de tous les fichiers partagés du frontend dans un dossier _shared/_.
- Mise à jour du code permettant l'export au format Shape. Utilisation des noms de méthodes non dépréciés.
- Refactorisation de la majorité du code du frontend.
- Le bouton d'accès au site occupe maintenant la première colonne de la liste afin d'éviter qu'il ne soit pas accessible sur les petits écrans.
- La liste des sites est maintenant triés sur la colonne de dernière visite. Les sites ayant eu les visites les plus récentes sont affichés en premier.
- Sur les grands écrans, les listes occupent maintenant toute l'espace disponible.

### 🐛 Corrigé

- Les mailles de la carte lors de l'édition d'une visite sont maintenant correctement initialisé avec les présences et abscences (#67).
- Les mailles de présence et abscence sont correctement comptés lors de l'édition d'une visite.
- Le contenu des attributs des fichiers Shape d'export sont maintenant correctement encodé en UTF-8. Il n'y a plus de problème avec les caractères accentués.
- La vérification de l'année de la visite est maintenant correctement réalisé et génère une pop-up d'information.
- Utilisation du format REST pour les chemins des web services.
- La vérification des droits autorisant un utilisateur à éditer une visite est à nouveau fonctionnelle.


## [1.1.1] - 2022-11-22

### 🔄 Modifié

- Changement du chemin du web service `/export_visit` pour `/visits/export` afin de mieux respecter les principes REST.
- Les paramètres du web service `/visits/export` peuvent maintenant être utilisé de manière combinés.
- ⚠️ La vue `pr_monitoring_flora_territory.export_visits` a été corrigé afin de supporter les sites sans commune. Nous n'avons pas utilisé de révision Alembic pour la mise à jour. Il est nécessaire de mettre à jour cette vue manuellement à l'aide de Psql par exemple. Voir le code SQL de la vue dans le fichier [schema.sql](backend/gn_module_monitoring_flora_territory/migrations/data/schema.sql).
- Ajout de la sauvegarde du filtre taxon entre deux utilisations des filtres sur la vue liste des sites.

### 🐛 Corrigé

- Autorisé les sites a ne pas avoir de commune associé dans le cas des sites hors France. Corrige l'export des visites et l'affichage des informations du site.
- Suppression des avertissements liés à l'utilisation du mode récursif avec la bibliothèque `utils_flask_sqla`.
- Correction de la gestion des perturbations dans le formulaire d'édition d'une visite.


## [1.1.0] - 2022-11-22

### 🚀 Ajouté

- Ajout d'un fichier de config par défaut pour tous les scripts Bash : `settings.default.ini`
- Ajout d'un fichier de config par défaut pour les scripts d'import : `imports_settings.default.ini`
- Sauvegarde des valeurs des filtres de la liste des sites.
- Ajout d'un fichier `.prettierrc` contenant les règles de formatage du frontend.
- Les filtres de la liste des sites sont désormais sauvegardé entre deux utilisations.

### 🔄 Modifié

- Déplacement des fichiers de configuration `.ini` dans le dossier `config/` du dossier `bin/`.
- L'import des visites gère désormais les observateurs sans organisme. Utiliser le mot clé "`INCONNU`" pour indiquer l'organisme de l'observateur.
- Le filtre des années permet de sélectionner une année existant sour forme de liste déroulante.
- Formatage du code source du Backend à l'aide de Black.
- Formatage du code source du Frontend à l'aide de Prettier.
- L'export au format GeoJson produit un fichier avec l'extension `.geojson` à la place de `.json`.
- Le rendu de l'interface de la liste des sites a été amélioré (ajout d'icônes) et unifié vis à vis du module _Priority Flora_.

### 🐛 Corrigé

- Correction du fonctionnement des scripts d'import qui ne fonctionnaient plus suite à la
  suppression du fichier de configuration par défaut.
- Les observateurs ajoutés via le script d'import des visites sont désormais activés afin de pouvoir être sélectionné dans les formulaires.
- Le code du module et l'identifiant du jeu de données du module sont directement récupéré dans web service et ne bloque plus l'enregistrement d'une visite.
- Toutes les informations d'un site sont correctement renvoyées et affichées sur la fiche d'un site.
- Les filtres _Commune_ et _Organisme_ utilise un identifiant et non plus un nom pour filtrer les résultats.


## [1.0.0] - 2022-09-22

Version stable du module compatible avec GeoNature version 2.9.2.

### 🚀 Ajouté

- Ajout du support d'Alembic.
- Module au nouveau format "packagé" de GeoNature (restructuration des dossiers et fichiers).
- Utilisation des codes à la place des ID dans les paramètres.
- Mise à jour de la documentation d'installation.

### 🐛 Corrigé

- Utilisation de la nouvelle syntaxe utils-flask-sqla.
- Amélioration de la gestion du code SQL commun aux différents modules Conservation.


## [1.0.0-beta] - 2020-07-07

Première version stable du module compatible avec GeoNature version 2.3.2 et plus.

### 🚀 Ajouté

- Mise à jour de la documentation et du changelog (issue #22)
- Simplification des la gestion des fichiers de configuration.
- Ajout de scripts d'import (et de suppression) pour les taxons, les nomenclatures, les mailles, les sites et les visites
- Ajout d'un paramètre pour le niveau de zoom par défaut des cartes du module.uninstall.sh (issue #45)
- Ajout d'un script de désinstallation du module (`uninstall.sh`)
- Affichage abrégé de l'ensemble des observateurs sur la liste des visites et complet sur le fiche (issue #41)
- Prise en compte de l'abscence d'observateur associé à une visite dans la liste et la fiche d'une visite (issue #40)
- Prise en compte de l'identifiant d'une liste d'utilisateurs dédiée pour le module SFT (issue #35)

### 🐛 Corrigé

- Amélioraton du script d'installation (issue #33)
- Prise en compte d'un jeu de données auquel associer les visites (issue #51)
- Modification possible d'une visite après affichage du message d'erreur du contrôle d'année (issue #37, #31)
- Correction du compteur de mailles avec présence/abscence (issue #39)
- Correction de l'affichage multiple du nom de la commune sur la fiche d'une visite (issue #52)
- Lors de la modification d'une visite les observateurs et perturbation s'affiche à nouveau (issue #53)
- Utilisation d'une seule entrée ("Tous") pour réinitialiser les filtres (issue #34)
- Dédoublonage de l'affiche du nom de la commune sur la fiche d'une visite (issue #38)
- Les organismes liées aux visites d'un site sont tous affichés dans la liste des sites quelque soit le filtre d'organisme sélectionné (issue #56)
- Les filtres des sites sont correctement pris en compte sans décalage et de façon cumulée (issue #56)
- Les exports sont à nouveau fonctionnels et ne bloquent plus (tester avec un export de 10 000 lignes) (issue #46)


## [0.1.0] - 2018-10-23

Première version du module GeoNature du protocole Suivi flore territoire du réseau Flore Sentinelle, piloté par le CBNA, développée par @Khanh-Chau.

![SFT screenshot](http://geonature.fr/docs/img/2018-09-sft.jpg)

Démonstration : http://geonature.fr/docs/img/2018-10-geonature-sft-demo.gif

Sur chacun de ces sites, une espèce est prospectée régulièrement par mailles de 25m, et l'absence ou la présence de l'espèce est renseignée pour chaque maille.

### 🚀 Ajouté

- MCD stabilisé et basé sur le schéma générique `gn_monitoring` (#1)
- Liste des sites filtrable par taxon, année de visite, commune et organisme
- Fiche détail d'un site avec la liste de ses visites
- Fiche détail de chaque visite
- Formulaire d'ajout ou de modification d'une visite, avec saisie simplifiée des présences/absences en clic droit ou gauche sur les mailles affichées sur la carte
- Export des visites par site ou par recherche globale
- Automatisation de l'installation de la BDD avec possibilité d'intégrer ou non des données exemple
- Documentation de l'installation et de l'intégration de données
- Paramètres de l'application surcouchables
