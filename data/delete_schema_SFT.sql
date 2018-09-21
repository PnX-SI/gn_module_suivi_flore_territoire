-- Supprimer un schéma -- 
DROP SCHEMA  pr_monitoring_flora_territory CASCADE;

-- Supprimer nomenclature des perturbations dans t_nomenclature --
DELETE FROM ref_nomenclatures.t_nomenclatures where id_type=ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION');

-- Supprimer TYPE_PERTURBATION dans bib_nomenclature--
DELETE FROM ref_nomenclatures.bib_nomenclatures_types where id_type=ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION');


-- Supprimer nomenclature zp dans t_nomenclature --

ALTER TABLE gn_monitoring.t_base_sites  DROP CONSTRAINT fk_t_base_sites_type_site; 

ALTER TABLE ONLY gn_monitoring.t_base_sites
    ADD CONSTRAINT fk_t_base_sites_type_site FOREIGN KEY (id_nomenclature_type_site) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE ON DELETE CASCADE; 
-- ATTENTION: CETTE ACTION VA AUSSI SUPPRIMER TOUTES LES DONNÉES DANS T_BASE_SITES, ET DONC T_BASE_VISITS, ET COR_SITE_AREA, COR_SITE_APPLICATION, COR SITE OBSERVER:
DELETE FROM ref_nomenclatures.t_nomenclatures where cd_nomenclature='ZP';

DELETE FROM gn_monitoring.cor_site_area;

-- Supprimer mailles 25*25
ALTER TABLE ref_geo.l_areas  DROP CONSTRAINT fk_l_areas_id_type ; 


ALTER TABLE ONLY ref_geo.l_areas
    ADD CONSTRAINT fk_l_areas_id_type FOREIGN KEY (id_type)
      REFERENCES ref_geo.bib_areas_types (id_type) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ref_geo.li_grids  DROP CONSTRAINT fk_li_grids_id_area ; 

ALTER TABLE ONLY ref_geo.li_grids ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;
       

DELETE FROM ref_geo.bib_areas_types where type_code='M25m';

