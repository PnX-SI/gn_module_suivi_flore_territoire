# CHANGELOG

## v1.0.0 (unreleased)

Première version stable du module compatible avec GeoNature v2.3.2.

**Fonctionnalités**
* Ajout de scripts d'import (suppression) pour les taxons, les nomenclatures, les mailles, les sites et les visites
* Ajout d'un paramètre pour le niveau de zoom par défaut des cartes du module.uninstall.sh (issue #45)
* Ajout d'un script de désinstallation du module (`uninstall.sh`)
* Mise à jour de la documentation et du changelog (issue #22)
* Affichage abrégé de l'ensemble des observateurs sur la liste des visites et complet sur le fiche (issue #41)
* Prise en compte de l'abscence d'observateur associé à une visite dans la liste et la fiche d'une visite (issue #40)
* Prise en compte de l'id d'une liste d'utilisateurs dédiée pour le module SFT (issue #35)

**Corrections**
* Amélioraton du script d'installation (issue #33)
* Prise en compte d'un jeu de données auquel associer les visites (issue #51)
* Modification possible d'une visite après affichage du message d'erreur du contrôle d'année (issue #37, #31)
* Correction du compteur de mailles avec présence/abscence (issue #39)
* Correction de l'affichage multiple du nom de la commune sur la fiche d'une visite (issue #52)
* Lors de la modification d'une visite les observateurs et perturbation s'affiche à nouveau (issue #53)
* Utilisation d'une seule entrée ("Tous") pour réinitialiser les filtres (issue #34)
* Dédoublonage de l'affiche du nom de la commune sur la fiche d'une visite (issue #38)
* Les organismes liées aux visites d'un site sont tous affichés dans la liste des sites quelque soit le filtre d'organisme sélectionné (issue #56)
* Les filtres des sites sont correctement pris en compte sans décalage et de façon cumulée (issue #56)
* Les exports sont à nouveau fonctionnels et ne bloquent plus (tester avec un export de 10 000 lignes) (issue #46)

## v0.1.0 (2018-10-23)

Première version du module GeoNature du protocole Suivi flore territoire du réseau Flore Sentinelle, piloté par le CBNA, développée par @Khanh-Chau.

.. image :: http://geonature.fr/docs/img/2018-09-sft.jpg

Démonstration : http://geonature.fr/docs/img/2018-10-geonature-sft-demo.gif

Sur chacune de ces ZP, une espèce est prospectée régulièrement par mailles de 25m, et l'absence ou la présence de l'espèce est renseignée pour chaque maille.

**Fonctionnalités**

* MCD stabilisé et basé sur le schéma générique ``gn_monitoring`` (#1)
* Liste des ZP filtrable par taxon, année de visite, commune et organisme
* Fiche détail d'une ZP avec la liste de ses visites
* Fiche détail de chaque visite
* Formulaire d'ajout ou de modification d'une visite, avec saisie simplifiée des présences/absences en clic droit ou gauche sur les mailles affichées sur la carte
* Export des visites par ZP ou par recherche globale
* Automatisation de l'installation de la BDD avec possibilité d'intégrer ou non des données exemple
* Documentation de l'installation et de l'intégration de données
* Paramètres de l'application surcouchables

**A venir**

* Corrections de bugs et améliorations : https://github.com/PnX-SI/gn_module_suivi_flore_territoire/issues
* Triggers SFT > Synthèse (#23)
