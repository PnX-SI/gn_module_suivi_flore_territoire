BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Add new format columns if not exists'
ALTER TABLE :moduleSchema.:meshesTmpTable
    ADD COLUMN IF NOT EXISTS :meshTypeColumn VARCHAR(10) DEFAULT :'meshesCode',
    ADD COLUMN IF NOT EXISTS :meshActionColumn VARCHAR(1) DEFAULT 'A',
    ADD COLUMN IF NOT EXISTS area_id INT ;

\echo '--------------------------------------------------------------------------------'
\echo 'Add area id into meshes temporary table'
UPDATE :moduleSchema.:meshesTmpTable AS m SET
	area_id = a.id_area
FROM ref_geo.l_areas AS a
WHERE a.area_code = m.:meshNameColumn
	AND a.id_type = ref_geo.get_id_area_type(m.:"meshTypeColumn")
    AND a.comment = CONCAT('SFT import date: ', :'importDate');

\echo '--------------------------------------------------------------------------------'
\echo 'Disable dependencies of "ref_geo.l_areas" to speed the deleting'
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities DISABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_area;

DO
$$
BEGIN
    IF EXISTS(
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'gn_synthese'
            AND table_name = 'cor_area_taxon'
    ) THEN
        ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT fk_cor_area_taxon_id_area;
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT fk_cor_sensitivity_area_id_area_fkey;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT fk_cor_site_area_id_area;
ALTER TABLE :moduleSchema.cor_visit_grid DROP CONSTRAINT fk_cor_visit_grid_id_area;

\echo '--------------------------------------------------------------------------------'
\echo 'Add index to speed deleting on ref_geo.l_areas'
CREATE INDEX IF NOT EXISTS index_l_areas_id_type_area_name ON ref_geo.l_areas (id_type, area_name);

COMMIT;

BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete from li_grids'
DELETE FROM ref_geo.li_grids
WHERE id_area IN (
    SELECT area_id
    FROM :moduleSchema.:meshesTmpTable
    WHERE :meshActionColumn = 'A'
) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete from cor_site_area'
DELETE FROM gn_monitoring.cor_site_area
WHERE id_area IN (
    SELECT area_id
    FROM :moduleSchema.:meshesTmpTable
    WHERE :meshActionColumn = 'A'
) ;

\echo '--------------------------------------------------------------------------------'
\echo 'Delete from cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT area_id
    FROM :moduleSchema.:meshesTmpTable
    WHERE :meshActionColumn = 'A'
) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete meshes in ref_geo.l_areas'
DELETE FROM ref_geo.l_areas
WHERE id_area IN (
    SELECT area_id
    FROM :moduleSchema.:meshesTmpTable
    WHERE :meshActionColumn = 'A'
);

\echo '--------------------------------------------------------------------------------'
\echo 'Clean database: remove temporary table'
DROP TABLE :moduleSchema.:meshesTmpTable;

COMMIT;

BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Enable constraints and triggers linked to "ref_geo.l_areas"'
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

DO
$$
BEGIN
    IF EXISTS(
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'gn_synthese'
            AND table_name = 'cor_area_taxon'
    ) THEN
        ALTER TABLE gn_synthese.cor_area_taxon ADD CONSTRAINT fk_cor_area_taxon_id_area
            FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
            ON UPDATE cascade ;
    END IF;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE gn_sensitivity.cor_sensitivity_area ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;
ALTER TABLE gn_monitoring.cor_site_area ADD CONSTRAINT fk_cor_site_area_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;
ALTER TABLE :moduleSchema.cor_visit_grid ADD CONSTRAINT fk_cor_visit_grid_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas (id_area) ;

-- ----------------------------------------------------------------------------
COMMIT;
