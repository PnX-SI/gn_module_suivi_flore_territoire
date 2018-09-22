======================
Suivi Flore Territoire
======================

Module GeoNature du protocole Suivi flore territoire du réseau Flore Sentinelle, piloté par le CBNA. 

A partir de Zones de Prospection (ZP) prospectées dans le protocole d'inventaire répété Bilan Stationnel (ex-Flore prioritaire), 
des ZP sont selectionnées pour faire office d'un suivi. Sur chacune de ces ZP, une espèce est prospectée régulièrement par mailles de 25m 
et l'absence ou la présence de l'espèce est renseignée pour chaque maille.

Présentation :

* Rapport de stage de Khanh-Chau Nguyen : http://geonature.fr/documents/2018-09-Nguyen-Khanh-Chau-Rapport-stage-M2DCISS.pdf
* Présentation de soutenance de stage de Khanh-Chau Nguyen : http://geonature.fr/documents/2018-09-Nguyen-Khanh-Chau-Soutenance-stage-M2DCISS.pdf

Installation
============

* Installez GeoNature (https://github.com/PnX-SI/GeoNature)
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_suivi_flore_territoire/archive/X.Y.Z.zip``) dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Créez et adaptez le fichier ``config/settings.ini`` à partir de ``config/settings.ini.sample``
* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes ``source venv/bin/activate`` puis ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>`` (exemple ``geonature install_gn_module /home/`whoami`/gn_module_suivi_flore_territoire-X.Y.Z /suivi_flore_territoire``)
* Configurez le module en modifiant son fichier ``config/gn_module_config.toml`` à partir du fichier ``config/conf_gn_module.toml.example``
* Lancez la génération de la configuration avec le commande ``geonature update_module_configuration suivi_flore_territoire``

Licence
=======

* OpenSource - GPL-3.0
* Copyleft 2018 - Parc National des Écrins - Conservatoire National Botanique Alpin

.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr

.. image:: http://www.cbn-alpin.fr/images/stories/habillage/logo-cbna.jpg
    :target: http://www.cbn-alpin.fr
