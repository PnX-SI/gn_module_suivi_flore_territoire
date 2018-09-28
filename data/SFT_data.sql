-- créer nomenclature  ZP --  
INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr, source )
VALUES (ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE'), 'ZP', 'Zone de prospection', 'Zone de prospection - suivi flore territoire', 'Zone de prospection',  'Zone de prospection issu du module suivi flore territoire', 'CBNA');

-- PROVISOIRE A ADAPTER GRACE AU SHAPEFILE DU CBNA

-- insérer les données dans t_base_sites grâce à celles dans la table zp_tmp
-- ATTENTION: il faut que le zp_tmp.shp soit en 2154, sinon ça donne des erreurs pour afficher les Zp.  
INSERT INTO gn_monitoring.t_base_sites
(id_nomenclature_type_site, base_site_name, base_site_description,  base_site_code, first_use_date, geom )
SELECT ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'ZP'), '', '', id, '01-01-2018', ST_TRANSFORM(ST_SetSRID(geom, MY_SRID_LOCAL), MY_SRID_WORLD)
FROM pr_monitoring_flora_territory.zp_tmp;

--- update le nom du site
-- UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, id_base_site); 

-- extension de la table t_base_sites : mettre les données dans t_infos_site
INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
SELECT id_base_site, zp.cd_nom
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON zp.id::character varying = bs.base_site_code;

--TODO--
-- parametrer ref_geo.bib_areas_types -- 
-- créer les mailles 25*25 
INSERT INTO ref_geo.bib_areas_types (type_name, type_code, type_desc)
VALUES ('Mailles25*25m', 'M25m', 'Maille INPN redécoupé en 25m');

--insérer les mailles dans l_areas grâce au fichier maille_tmp
INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
SELECT ref_geo.get_id_area_type('M25m'), id, id, geom, ST_CENTROID(geom), 'INPN'
FROM pr_monitoring_flora_territory.maille_tmp;

-- insérer les mailles dans li_grids
INSERT INTO ref_geo.li_grids
SELECT area_code, id_area, ST_XMin(ST_Extent(geom)), ST_XMax(ST_Extent(geom)), ST_YMin(ST_Extent(geom)),ST_YMax(ST_Extent(geom))
FROM ref_geo.l_areas
WHERE id_type=ref_geo.get_id_area_type('M25m')
GROUP by area_code, id_area;

-- Intersections mailles 25*25 et les ZP --> affiche maille

INSERT INTO gn_monitoring.cor_site_area (id_base_site, id_area)
SELECT bs.id_base_site, a.id_area 
FROM ref_geo.l_areas a
JOIN gn_monitoring.t_base_sites bs ON ST_Within(ST_TRANSFORM(a.geom, MY_SRID_WORLD), bs.geom)
WHERE id_type=ref_geo.get_id_area_type('M25m');

-- Intersections communes et ZP --> affiche nom commune  
-- Cette fonction est gérée automatiquement par des triggers dans gn_monitoring
-- il faut que le type_code de Communes dans ref_geo.l_areas soit 'COM'
-- INSERT INTO gn_monitoring.cor_site_area (id_base_site, id_area)
-- SELECT bs.id_base_site, a.id_area
-- FROM ref_geo.l_areas a
-- JOIN gn_monitoring.t_base_sites bs ON ST_intersects(ST_TRANSFORM(a.geom, MY_SRID_WORLD), bs.geom)
-- WHERE id_type=ref_geo.get_id_area_type('COM');


-- Insérer dans cor_site_application les sites suivi de ce module
INSERT INTO gn_monitoring.cor_site_application 
SELECT  bs.id_base_site, MY_ID_MODULE
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON bs.base_site_code  = zp.id::character varying;