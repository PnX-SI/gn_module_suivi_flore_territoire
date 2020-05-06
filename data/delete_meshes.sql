BEGIN;

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

-- Add index to speed deleting on ref_geo.l_areas
CREATE INDEX IF NOT EXISTS index_l_areas_id_type_area_name ON ref_geo.l_areas (id_type, area_name);

COMMIT;

BEGIN;

DELETE FROM ref_geo.li_grids
    WHERE id_area IN (
        SELECT id_area FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type(:'meshesCode')
            AND area_name IN (SELECT :meshNameColumn FROM :moduleSchema.:meshesTmpTable)
            AND comment = CONCAT('SFT import date: ', :'importDate')
    ) ;

DELETE FROM gn_monitoring.cor_site_area
    WHERE id_area IN (
        SELECT id_area FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type(:'meshesCode')
            AND area_name IN (SELECT :meshNameColumn FROM :moduleSchema.:meshesTmpTable)
            AND comment = CONCAT('SFT import date: ', :'importDate')
    ) ;

-- Delete meshes in ref_geo.l_areas
DELETE FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type(:'meshesCode')
        AND area_name IN (SELECT :meshNameColumn FROM :moduleSchema.:meshesTmpTable)
        AND comment = CONCAT('SFT import date: ', :'importDate')
        ;

-- Clean database: remove temporary table
DROP TABLE :moduleSchema.:meshesTmpTable;

COMMIT;

BEGIN;

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

COMMIT;
