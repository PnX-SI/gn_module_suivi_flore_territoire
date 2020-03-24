BEGIN;

-- Remove link between sites and the SFT module
DELETE FROM gn_monitoring.cor_site_module 
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTmpTable AS tmp 
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code) 
    ) ;

-- Remove links between sites and areas
DELETE FROM gn_monitoring.cor_site_area 
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTmpTable AS tmp 
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code) 
    ) ;

-- Remove extended site infos
DELETE FROM :moduleSchema.t_infos_site 
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTmpTable AS tmp 
                ON (tmp.:siteCodeColumn::character varying = bs.base_site_code) 
    ) ;

-- Remove base sites
DELETE FROM gn_monitoring.t_base_sites 
    WHERE base_site_code IN (
        SELECT :siteCodeColumn::character varying FROM :moduleSchema.:sitesTmpTable
    ) ;

-- Clean database : remove temporary table
DROP TABLE :moduleSchema.:sitesTmpTable ;

COMMIT;
