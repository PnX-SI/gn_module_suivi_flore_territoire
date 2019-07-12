
ALTER TABLE DATABASE_SCHEMA.DATABASE_TABLE  
ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, MY_SRID_LOCAL) 
USING ST_Force2D(geom);

-- insérer les données dans t_base_sites grâce à celles dans la table zp
-- ATTENTION: il faut que le fichier shp soit en 2154, sinon ça donne des erreurs pour afficher les Zp.  

INSERT INTO gn_monitoring.t_base_sites
(id_nomenclature_type_site, base_site_name, base_site_description,  base_site_code, first_use_date, geom )
SELECT ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'ZP'), 'ZP-', '', idzp, now(), ST_TRANSFORM(ST_SetSRID(geom, MY_SRID_LOCAL), MY_SRID_WORLD)
FROM DATABASE_SCHEMA.DATABASE_TABLE;

--- update le nom du site pour y ajouter l'identifiant du site
UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, base_site_code); 


-- extension de la table t_base_sites : mettre les données dans t_infos_site
INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
SELECT bs.id_base_site, zp.cd_nom
FROM gn_monitoring.t_base_sites bs
JOIN DATABASE_SCHEMA.DATABASE_TABLE zp ON zp.idzp::character varying = bs.base_site_code;

DROP TABLE DATABASE_SCHEMA.DATABASE_TABLE;