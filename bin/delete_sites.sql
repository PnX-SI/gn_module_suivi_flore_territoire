BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Remove link between sites and the SFT module'
DELETE FROM gn_monitoring.cor_site_module
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTmpTable AS tmp
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code)
        WHERE bs.first_use_date = :'importDate'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove links between sites and areas'
DELETE FROM gn_monitoring.cor_site_area
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTmpTable AS tmp
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code)
        WHERE bs.first_use_date = :'importDate'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove extended site infos'
-- TODO: check if that taxon is not use by a other visit from an other import
DELETE FROM :moduleSchema.t_infos_site AS tis
    WHERE EXISTS (
        SELECT 1
        FROM :moduleSchema.:sitesTmpTable AS tmp
            JOIN gn_monitoring.t_base_sites AS bs
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code)
        WHERE tis.id_base_site = bs.id_base_site
            AND tis.cd_nom = tmp.:siteTaxonColumn
            AND first_use_date = :'importDate'
    );


\echo '--------------------------------------------------------------------------------'
\echo 'Remove base sites'
DELETE FROM gn_monitoring.t_base_sites
    WHERE base_site_code IN (
        SELECT :siteCodeColumn::character varying FROM :moduleSchema.:sitesTmpTable
    )
    AND first_use_date = :'importDate';

-- Clean database : remove temporary table
DROP TABLE :moduleSchema.:sitesTmpTable ;

-- ----------------------------------------------------------------------------
COMMIT;
