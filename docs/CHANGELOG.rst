=========
CHANGELOG
=========

0.2.0 (unreleased)
------------------

**Corrections**

* 


0.1.0 (2018-10-23)
------------------

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
