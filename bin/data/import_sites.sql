-- Script SQL to import sites (use with `import_sites.sh`)
BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Force SRID on geometry colum of temporary sites table'
ALTER TABLE :moduleSchema.:sitesTmpTable
    ALTER COLUMN :siteGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
    USING ST_Force2D(:siteGeomColumn) ;

\echo '--------------------------------------------------------------------------------'
\echo 'Add new format columns if not exists'
ALTER TABLE :moduleSchema.:sitesTmpTable
    ADD COLUMN IF NOT EXISTS :siteActionColumn VARCHAR(1) DEFAULT 'A',
    ADD COLUMN IF NOT EXISTS base_site_id INT ;

\echo '--------------------------------------------------------------------------------'
\echo 'Add base site id into sites temporary table'
UPDATE :moduleSchema.:sitesTmpTable AS tmp SET
    base_site_id = bs.id_base_site
FROM gn_monitoring.t_base_sites AS bs
WHERE tmp.:siteCodeColumn::VARCHAR = bs.base_site_code
    AND tmp.:siteActionColumn = 'M';

\echo '--------------------------------------------------------------------------------'
\echo 'Insert data in `t_base_sites` with data in temporary table'
\echo 'WARNING: your Shape file must used the same SRID than you database (usually 2154)'
INSERT INTO gn_monitoring.t_base_sites
    (id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom)
    SELECT
        ref_nomenclatures.get_id_nomenclature('TYPE_SITE', :'siteTypeCode'),
        CONCAT(:'siteTypeCode', '-', :siteCodeColumn::character varying),
        :siteDescColumn,
        :siteCodeColumn,
        DATE(:'importDate'),
        ST_TRANSFORM(ST_SetSRID(:siteGeomColumn, :sridLocal), :sridWorld)
    FROM :moduleSchema.:sitesTmpTable AS st
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM gn_monitoring.t_base_sites AS bs
            WHERE bs.base_site_code = st.:siteCodeColumn::character varying
        )
        AND st.:siteActionColumn = 'A' ;


\echo '--------------------------------------------------------------------------------'
\echo 'Update base sites'
UPDATE gn_monitoring.t_base_sites AS bs SET
    base_site_name = CONCAT(:'siteTypeCode', '-', s.:siteCodeColumn::VARCHAR),
    base_site_description = s.:siteDescColumn,
    base_site_code = s.:siteCodeColumn,
    geom = ST_TRANSFORM(ST_SetSRID(s.:siteGeomColumn, :sridLocal), :sridWorld)
FROM :moduleSchema.:sitesTmpTable AS s
WHERE bs.id_base_site = s.base_site_id
    AND s.:siteActionColumn = 'M' ;


\echo '--------------------------------------------------------------------------------'
\echo 'Add extended site infos in t_infos_sites"'
INSERT INTO :moduleSchema.t_infos_site (id_base_site, cd_nom)
    SELECT bs.id_base_site, tmp.:siteTaxonColumn
    FROM gn_monitoring.t_base_sites AS bs
        JOIN :moduleSchema.:sitesTmpTable AS tmp
            ON (tmp.:siteCodeColumn::character varying = bs.base_site_code)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM :moduleSchema.t_infos_site AS tbs
            WHERE tbs.id_base_site = bs.id_base_site
                AND tbs.cd_nom = tmp.:siteTaxonColumn
        )
        AND tmp.:siteActionColumn = 'A'
ON CONFLICT ON CONSTRAINT pk_id_t_infos_site DO NOTHING ;


\echo '--------------------------------------------------------------------------------'
\echo 'Update infos sites'
UPDATE :moduleSchema.t_infos_site AS tis SET
    cd_nom = s.:siteTaxonColumn
FROM :moduleSchema.:sitesTmpTable AS s
WHERE tis.id_base_site = s.base_site_id
    AND s.:siteActionColumn = 'M' ;

\echo '--------------------------------------------------------------------------------'
\echo 'Insert into "cor_site_application" the monitoring sites'
INSERT INTO gn_monitoring.cor_site_module (id_base_site, id_module)
    WITH
        sites AS (
            SELECT bs.id_base_site AS id
            FROM gn_monitoring.t_base_sites bs
                JOIN :moduleSchema.:sitesTmpTable AS tmp
                    ON (bs.base_site_code = tmp.:siteCodeColumn::character varying)
            WHERE tmp.:siteActionColumn = 'A'
        ),
        module AS (
            SELECT id_module AS id
            FROM gn_commons.t_modules
            WHERE module_code ILIKE :'moduleCode'
        )
    SELECT sites.id, module.id FROM sites, module
ON CONFLICT ON CONSTRAINT pk_cor_site_module DO NOTHING ;


-- ----------------------------------------------------------------------------
COMMIT;
