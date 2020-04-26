-- Script SQL to import sites (use with `import_sites.sh`)
BEGIN;

ALTER TABLE :moduleSchema.:sitesTmpTable
ALTER COLUMN :siteGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
USING ST_Force2D(:siteGeomColumn) ;

-- Insert data in `t_base_sites` with data in temporary table
-- WARNING: your Shape file must used the same SRID than you database (usually 2154)
INSERT INTO gn_monitoring.t_base_sites
    (id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom)
    SELECT
        ref_nomenclatures.get_id_nomenclature('TYPE_SITE', :'siteTypeCode'),
        CONCAT(:'siteTypeCode', '-', :siteCodeColumn::character varying),
        :siteDescColumn,
        :siteCodeColumn,
        NOW(),
        ST_TRANSFORM(ST_SetSRID(:siteGeomColumn, :sridLocal), :sridWorld)
    FROM :moduleSchema.:sitesTmpTable
WHERE NOT EXISTS (
    SELECT id_base_site
    FROM gn_monitoring.t_base_sites AS bs
        JOIN :moduleSchema.:sitesTmpTable AS st
            ON (bs.base_site_code = st.:siteCodeColumn::varchar)
) ;

-- Add extended site infos in 't_infos_sites'
INSERT INTO :moduleSchema.t_infos_site (id_base_site, cd_nom)
    SELECT bs.id_base_site, tmp.:siteTaxonColumn
    FROM gn_monitoring.t_base_sites AS bs
        JOIN :moduleSchema.:sitesTmpTable AS tmp
            ON (tmp.:siteCodeColumn::character varying = bs.base_site_code)
ON CONFLICT ON CONSTRAINT pk_id_t_infos_site DO NOTHING ;

-- Insérer dans cor_site_application les sites suivis de ce module
INSERT INTO gn_monitoring.cor_site_module (id_base_site, id_module)
    WITH
        sites AS (
            SELECT bs.id_base_site AS id
            FROM gn_monitoring.t_base_sites bs
                JOIN :moduleSchema.:sitesTmpTable AS tmp
                    ON (bs.base_site_code = tmp.:siteCodeColumn::character varying)
        ),
        module AS (
            SELECT id_module AS id
            FROM gn_commons.t_modules
            WHERE module_code ILIKE :'moduleCode'
        )
    SELECT sites.id, module.id FROM sites, module
ON CONFLICT ON CONSTRAINT pk_cor_site_module DO NOTHING ;

-- Clean database: remove temporary table
DROP TABLE :moduleSchema.:sitesTmpTable ;

COMMIT;
