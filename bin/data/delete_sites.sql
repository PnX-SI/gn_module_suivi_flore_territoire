BEGIN;

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
    AND bs.first_use_date = :'importDate';

\echo '--------------------------------------------------------------------------------'
\echo 'Remove link between sites and the SFT module'
DELETE FROM gn_monitoring.cor_site_module
    WHERE id_base_site IN (
        SELECT base_site_id
        FROM :moduleSchema.:sitesTmpTable
        WHERE :siteActionColumn = 'A'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove links between sites and areas'
DELETE FROM gn_monitoring.cor_site_area
    WHERE id_base_site IN (
        SELECT base_site_id
        FROM :moduleSchema.:sitesTmpTable
        WHERE :siteActionColumn = 'A'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove extended site infos'
-- TODO: check if that taxon is not use by a other visit from an other import
DELETE FROM :moduleSchema.t_infos_site AS tis
    WHERE EXISTS (
        SELECT 1
        FROM :moduleSchema.:sitesTmpTable AS tmp
            JOIN gn_monitoring.t_base_sites AS bs
                ON (tmp.base_site_id = bs.id_base_site)
        WHERE bs.id_base_site = tis.id_base_site
            AND tmp.:siteTaxonColumn = tis.cd_nom
    );


\echo '--------------------------------------------------------------------------------'
\echo 'Remove base sites'
DELETE FROM gn_monitoring.t_base_sites
    WHERE id_base_site IN (
        SELECT base_site_id
        FROM :moduleSchema.:sitesTmpTable
        WHERE :siteActionColumn = 'A'
    ) ;

-- Clean database : remove temporary table
DROP TABLE :moduleSchema.:sitesTmpTable ;

-- ----------------------------------------------------------------------------
COMMIT;
