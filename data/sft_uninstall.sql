-- Script to remove SFT schema and all data linked to SFT insert in GeoNature DB 
BEGIN;

-- REF_TAXONOMY
-- Delete names list : taxonomie.bib_listes, taxonomie.cor_nom_liste, taxonomie.bib_noms
WITH names_deleted AS (
	DELETE FROM taxonomie.cor_nom_liste WHERE id_liste IN (
		SELECT id_liste FROM taxonomie.bib_listes WHERE nom_liste = :'taxonListName'
	)
	RETURNING id_nom
)
DELETE FROM taxonomie.bib_noms WHERE id_nom IN (
	SELECT id_nom FROM names_deleted 
);

DELETE FROM taxonomie.bib_listes WHERE nom_liste = :'taxonListName';

-- -----------------------------------------------------------------------------
-- REF_NOMENCLATURE
-- Delete nomenclature: ref_nomenclatures.t_nomenclatures,  ref_nomenclatures.bib_nomenclatures_types
DELETE FROM ref_nomenclatures.t_nomenclatures 
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'perturbationCode');

DELETE FROM ref_nomenclatures.bib_nomenclatures_types 
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'perturbationCode');

-- -----------------------------------------------------------------------------
-- GN_MONITORING

-- Remove link between sites and the SFT module
DELETE FROM gn_monitoring.cor_site_module 
    WHERE id_module = (
        SELECT id_module 
        FROM gn_commons.t_modules
        WHERE module_code ILIKE :'moduleCode'
    ) ;

-- Remove links between sites and areas
DELETE FROM gn_monitoring.cor_site_area WHERE id_base_site IN (
        SELECT id_base_site FROM :moduleSchema.t_infos_site
    ) ;

-- Remove base sites data
DELETE FROM gn_monitoring.t_base_sites 
    WHERE id_base_site IN (
        SELECT id_base_site FROM :moduleSchema.t_infos_site
    ) ;

-- -----------------------------------------------------------------------------
-- REF_GEO
-- Delete meshes
DELETE FROM ref_geo.li_grids 
    WHERE id_area IN (
        SELECT id_area FROM ref_geo.l_areas WHERE id_type = (
            SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = :'meshesCode'
        )
    );

-- Disable dependencies of "ref_geo.l_areas" to speed the deleting
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities DISABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_area;
ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT fk_cor_area_taxon_id_area;
ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT fk_cor_sensitivity_area_id_area_fkey;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT fk_cor_site_area_id_area;
ALTER TABLE :moduleSchema.cor_visit_grid DROP CONSTRAINT fk_cor_visit_grid_id_area;

DELETE FROM ref_geo.l_areas 
    WHERE id_type = (
        SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = :'meshesCode'
    );

--Enable constraints and triggers linked to "ref_geo.l_areas" 
ALTER TABLE ref_geo.li_municipalities ENABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.l_areas ENABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities ADD CONSTRAINT fk_li_municipalities_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) 
    ON UPDATE CASCADE ON DELETE cascade ;
ALTER TABLE ref_geo.li_grids ADD CONSTRAINT fk_li_grids_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) 
    ON UPDATE CASCADE ON DELETE cascade  ;
ALTER TABLE gn_synthese.cor_area_synthese ADD CONSTRAINT fk_cor_area_synthese_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) 
    ON UPDATE cascade ;
ALTER TABLE gn_synthese.cor_area_taxon ADD CONSTRAINT fk_cor_area_taxon_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) 
    ON UPDATE cascade ;
ALTER TABLE gn_sensitivity.cor_sensitivity_area ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;
ALTER TABLE gn_monitoring.cor_site_area ADD CONSTRAINT fk_cor_site_area_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;
ALTER TABLE :moduleSchema.cor_visit_grid ADD CONSTRAINT fk_cor_visit_grid_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area) ;


DELETE FROM ref_geo.bib_areas_types WHERE type_code = :'meshesCode';

-- -----------------------------------------------------------------------------
-- SFT
-- Delete SFT schema -- 
DROP SCHEMA :moduleSchema CASCADE;

-- -----------------------------------------------------------------------------
-- REF_NOMENCLATURE
-- Remove nomenclature site type value for SFT site
DELETE FROM ref_nomenclatures.t_nomenclatures WHERE cd_nomenclature = :'siteTypeCode';

COMMIT;
