
Intégrer les mailles
--------------------

* Ouvrir le SHP des mailles dans QGIS. Renommer la colonne contenant les noms des mailles en ``area_name``
* Selectionner toutes les mailles à importer
* Les copier (Edition / Copier les entités selectionnées)
* Ouvrir la table ``ref_geo.l_areas`` dans QGIS en mode édition
* Y coller les mailles (Edition / Coller les entités)
* Ouvrir la table attributaire de ``ref_geo.l_areas`` pour renseigner le id_type de toutes les mailles insérées (Calculatrice de champs / Mettre à jour id_type = 32)
* Enregistrer les modifications de la table ``ref_geo.l_areas``

Intrégrer les ZP
----------------

* Importer le SHP dans une table temporaire (``pr_monitoring_flora_territory.zp_tmp2`` dans cet exemple) de la BDD GeoNature avec QGIS
* Remplissez les tables de la BDD à partir de cette table temporaire : 

.. code:: sql

  INSERT INTO gn_monitoring.t_base_sites
  (id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom )
  SELECT ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'ZP'), 'ZP-', '', idzp, now(), ST_Force2D(ST_TRANSFORM(ST_SetSRID(geom, 2154), 4326))
  FROM pr_monitoring_flora_territory.zp_tmp2;

  UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, base_site_code);

  INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
  SELECT id_base_site, zp.cd_nom
  FROM gn_monitoring.t_base_sites bs
  JOIN pr_monitoring_flora_territory.zp_tmp2 zp ON zp.idzp::character varying = bs.base_site_code;

La table ``gn_monitoring.cor_site_area`` est remplie automatiquement par trigger pour indiquer les communes et mailles 25m de chaque ZP

Intrégrer les visites
---------------------

* Importer le CSV dans une table temporaire de la BDD avec QGIS (``pr_monitoring_flora_territory.obs_maille_tmp`` dans cet exemple)
* Identifier les organismes présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT organismes FROM pr_monitoring_flora_territory.obs_maille_tmp``
* Identifier les observateurs présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT observateu FROM pr_monitoring_flora_territory.obs_maille_tmp``
* Remplissez la table des visites : 

.. code:: sql

  INSERT INTO gn_monitoring.t_base_visits (id_base_site, visit_date_min, visit_date_max)
  SELECT DISTINCT s.id_base_site, replace(date_deb,'/','-')::date AS date_debut, replace(date_fin,'/','-')::date AS date_fin
  FROM pr_monitoring_flora_territory.obs_maille_tmp o
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code = o.idzp
