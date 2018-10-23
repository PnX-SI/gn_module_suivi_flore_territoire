
Intégrer les mailles
--------------------

* Ouvrir le SHP des mailles dans QGIS. Renommer la colonne contenant les noms des mailles en ``area_name``
* Selectionner toutes les mailles à importer. Verifier que vous n'intégrez pas des mailles déjà présentes
* Les copier (Edition / Copier les entités selectionnées)
* Ouvrir la table ``ref_geo.l_areas`` dans QGIS en mode édition
* Y coller les mailles (Edition / Coller les entités)
* Ouvrir la table attributaire de ``ref_geo.l_areas`` pour renseigner le ``id_type`` de toutes les mailles insérées (Calculatrice de champs / Mettre à jour ``id_type = 32``)
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

  UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, base_site_code)
  WHERE CAST (base_site_code AS INTEGER) IN (SELECT indexzp FROM pr_monitoring_flora_territory.zp_tmp2);

  INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
  SELECT bs.id_base_site, zp.cd_nom
  FROM gn_monitoring.t_base_sites bs
  JOIN pr_monitoring_flora_territory.zp_tmp2 zp ON zp.idzp::character varying = bs.base_site_code
  WHERE bs.id_nomenclature_type_site = ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'ZP');

La table ``gn_monitoring.cor_site_area`` est remplie automatiquement par trigger pour indiquer les communes et mailles 25m de chaque ZP.

* Insérer les sites suivis de ce module dans ``cor_site_application`` : 

.. code:: sql

  INSERT INTO gn_monitoring.cor_site_application 
  WITH idapp AS(
    SELECT id_application FROM utilisateurs.t_applications
    WHERE nom_application = 'suivi_flore_territoire'
  )
  SELECT ti.id_base_site, idapp.id_application
  FROM pr_monitoring_flora_territory.t_infos_site ti, idapp
  WHERE id_base_site NOT IN (SELECT id_base_site FROM gn_monitoring.cor_site_application);

Intégrer les visites
--------------------

* Importer le CSV dans une table temporaire de la BDD avec QGIS (``pr_monitoring_flora_territory.obs_maille_tmp`` dans cet exemple)
* Identifier les organismes présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT unnest(string_to_array(organismes, '|')) AS organismes FROM pr_monitoring_flora_territory.obs_maille_tmp ORDER BY organismes``
* Identifier les observateurs présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT unnest(string_to_array(observateu, '|')) AS observateurs FROM pr_monitoring_flora_territory.obs_maille_tmp ORDER BY observateurs``
* Corriger le nom mal formaté : ``UPDATE pr_monitoring_flora_territory.obs_maille_tmp SET observateu = replace(observateu, 'PARCHOUX|Franck', 'PARCHOUX Franck');``
* Remplissez la table des visites : 

.. code:: sql

  INSERT INTO gn_monitoring.t_base_visits (id_base_site, visit_date_min, visit_date_max)
  SELECT DISTINCT s.id_base_site, replace(date_deb,'/','-')::date AS date_debut, replace(date_fin,'/','-')::date AS date_fin
  FROM pr_monitoring_flora_territory.obs_maille_tmp o
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code = o.idzp
  
* Remplissez la table des observateurs : 

.. code:: sql

  INSERT INTO gn_monitoring.cor_visit_observer
      (id_base_visit, id_role)
  WITH myuser AS(SELECT lower(unnest(string_to_array(observateu, '|'))) AS obs,idzp FROM pr_monitoring_flora_territory.obs_maille_tmp),
  	roles AS(SELECT lower(nom_role ||' '|| prenom_role) AS nom, id_role FROM utilisateurs.t_roles)
  SELECT DISTINCT v.id_base_visit,r.id_role
  FROM myuser m
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code = m.idzp
  JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
  JOIN roles r ON m.obs=r.nom
  
* Remplissez la table des observations : 

.. code:: sql

  INSERT INTO pr_monitoring_flora_territory.cor_visit_grid (id_area, id_base_visit, presence)
  SELECT 
  	id_area,  
  	id_base_visit, 
  	CASE
       WHEN presence = 'na' THEN False
       WHEN presence = 'pr' THEN True
    END as presenceok
  FROM pr_monitoring_flora_territory.obs_maille_tmp o
  JOIN ref_geo.l_areas a ON a.area_name = o.cd25m
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code = o.idzp
  JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
  WHERE presence = 'na' OR presence = 'pr'

Vérifier les données
--------------------

.. code:: sql

  -- Nombre de ZP par taxon
  SELECT s.cd_nom, t.nom_valide, count(*) as nb_zp FROM pr_monitoring_flora_territory.t_infos_site s
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  GROUP BY s.cd_nom, t.nom_valide;
  
  -- Nombre de visites par taxon
  SELECT s.cd_nom, t.nom_valide, count(*) as nb_visites FROM gn_monitoring.t_base_visits v
  JOIN pr_monitoring_flora_territory.t_infos_site s ON s.id_base_site = v.id_base_site
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  GROUP BY s.cd_nom, t.nom_valide;
  
  -- Nombre de mailles visitées par taxon
  SELECT s.cd_nom, t.nom_valide, count(*) as nb_mailles_visitees FROM pr_monitoring_flora_territory.cor_visit_grid cv
  JOIN gn_monitoring.t_base_visits v ON v.id_base_visit = cv.id_base_visit
  JOIN pr_monitoring_flora_territory.t_infos_site s ON s.id_base_site = v.id_base_site
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  GROUP BY s.cd_nom, t.nom_valide;
  
  -- Nombre de présences/absences par taxon
  SELECT s.cd_nom, t.nom_valide, cv.presence, count(*) as nb_presence FROM pr_monitoring_flora_territory.cor_visit_grid cv
  JOIN gn_monitoring.t_base_visits v ON v.id_base_visit = cv.id_base_visit
  JOIN pr_monitoring_flora_territory.t_infos_site s ON s.id_base_site = v.id_base_site
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  GROUP BY s.cd_nom, t.nom_valide, cv.presence;

Fichiers PNE
------------

Les fichiers du PNE ont quelques différences. Voici les adaptations des requêtes : 

.. code:: sql

  -- Insérer les ZP
  INSERT INTO gn_monitoring.t_base_visits (id_base_site, visit_date_min, visit_date_max)
  SELECT DISTINCT s.id_base_site, date_debut, date_fin
  FROM pr_monitoring_flora_territory.obs_maille_tmp_remy o
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code::INTEGER = o.indexzp
  WHERE s.id_base_site=105 -- Limiter à un site manquant dans un second temps
  ;

  -- Lister les observateurs / Attentino à bien vérifier les observateurs déjà présents
  SELECT DISTINCT unnest(string_to_array(observateu, ', ')) AS observateurs, organismes 
  FROM pr_monitoring_flora_territory.obs_maille_tmp_remy ORDER BY observateurs;
  
  -- Insérer les observateurs des visites
  INSERT INTO gn_monitoring.cor_visit_observer
    (id_base_visit, id_role)
  WITH myuser AS(SELECT lower(unnest(string_to_array(observateu, ', '))) AS obs,indexzp 
  FROM pr_monitoring_flora_territory.obs_maille_tmp_remy),
      roles AS(SELECT lower(prenom_role ||' '|| nom_role) AS nom, id_role FROM utilisateurs.t_roles)
  SELECT DISTINCT v.id_base_visit,r.id_role
  FROM myuser m
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code::INTEGER = m.indexzp
  JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
  JOIN roles r ON m.obs=r.nom;

  -- Insérer les visites des mailles
  INSERT INTO pr_monitoring_flora_territory.cor_visit_grid (id_area, id_base_visit, presence)
  SELECT
        id_area,
        id_base_visit,
        CASE
       WHEN presence = 0 THEN False
       WHEN presence = 1 THEN True
    END as presenceok
  FROM pr_monitoring_flora_territory.obs_maille_tmp_remy o
  JOIN ref_geo.l_areas a ON a.area_name = o.id_maille
  JOIN gn_monitoring.t_base_sites s ON s.base_site_code::INTEGER = o.indexzp
  JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
  WHERE (presence = 0 OR presence = 1) AND s.id_base_site=105;
