SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA pr_monitoring_flora_territory;

SET search_path = pr_monitoring_flora_territory, pg_catalog;

SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_nom integer NOT NULL  
);
COMMENT ON TABLE pr_monitoring_flora_territory.t_infos_site IS 'Extension de t_base_sites de gn_monitoring, permet d\avoir les infos complémentaires d\un site';


CREATE TABLE cor_visit_grid (
    id_area integer NOT NULL,
    id_base_visit integer NOT NULL,
    presence boolean NOT NULL     
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_grid IS 'Enregistrer la présence/absence d\une espèce dans une maille définie lors d\une visite';


CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL   
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_perturbation IS 'Extension de t_base_visit de gn_monitoring, enregistrer les perturbations constatées lors d\une visite';


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT pk_id_t_infos_site PRIMARY KEY (id_infos_site);

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT pk_cor_visit_grid PRIMARY KEY (id_area, id_base_visit);

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT pk_cor_visit_perturbation PRIMARY KEY (id_base_visit, id_nomenclature_perturbation);



---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT fk_infos_site_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE; 

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_infos_site_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref (cd_nom) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area);


ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation FOREIGN KEY (id_nomenclature_perturbation) REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) ON UPDATE CASCADE;


------------
--TRIGGERS--
------------
-- Idée: 
-- + Un trigger pour vérifier si id_nomenclature_perturbation dans la table cor_visit_perturbation 
--   correspond bien à celui stocké dans t_nomenclatures. 

--------
--DATA--
--------

INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr )
VALUES (116, 'ZP', 'Zone de prospection', 'Zone de prospection - suivi flore territoire', 'Zone de prospection',  'Zone de prospection issu du module suivi flore territoire');

-- PROVISOIRE A ADAPTER GRACE AU SHAPEFILE DU CBNA
INSERT INTO gn_monitoring.t_base_sites
(id_inventor, id_digitiser, id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom )
SELECT 1, 1, 503, 'zp', '', id, '01-01-2018', ST_TRANSFORM(ST_SetSRID(geom, 2154), 4326)
FROM pr_monitoring_flora_territory.zp_tmp;

INSERT INTO pr_monitoring_flora_territory.t_infos_site (id_base_site, cd_nom)
SELECT id_base_site, zp.cd_nom
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON zp.id::character varying = bs.base_site_code;


INSERT INTO ref_geo.bib_areas_types (id_type, type_name, type_desc)
VALUES (203, 'Mailles25*25', 'Maille INPN 50*50 redécoupé en 25m');

INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
SELECT 203, id, id, geom, ST_CENTROID(geom), 'INPN'
FROM pr_monitoring_flora_territory.maille_tmp;

INSERT INTO ref_geo.li_grids
SELECT area_code, id_area, ST_XMin(ST_Extent(geom)), ST_XMax(ST_Extent(geom)), ST_YMin(ST_Extent(geom)),ST_YMax(ST_Extent(geom))
FROM ref_geo.l_areas
WHERE id_type=203
GROUP by area_code, id_area;


INSERT INTO gn_monitoring.cor_site_area (id_base_site, id_area)
SELECT bs.id_base_site, a.id_area 
FROM ref_geo.l_areas a
JOIN gn_monitoring.t_base_sites bs ON ST_Within(ST_TRANSFORM(a.geom, 4326), bs.geom)
WHERE id_type=203;

-- TODO Mettre en paramètre l'id du module
INSERT INTO gn_monitoring.cor_site_application
SELECT  bs.id_base_site, MY_ID_MODULE
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_flora_territory.zp_tmp zp ON bs.base_site_code  = zp.id::character varying;

DROP TABLE pr_monitoring_flora_territory.zp_tmp;
DROP TABLE pr_monitoring_flora_territory.maille_tmp;