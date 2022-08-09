-- Script to build SFT schema
-- -----------------------------------------------------------------------------
-- Set database variables
SET client_encoding = 'UTF8';

-- -----------------------------------------------------------------------------
-- Create SFT schema
CREATE SCHEMA pr_monitoring_flora_territory;


-- -----------------------------------------------------------------------------
-- Set new database variables
SET search_path = pr_monitoring_flora_territory, pg_catalog, public;
SET default_with_oids = false;


-- -----------------------------------------------------------------------------
-- TABLES

-- Table `t_infos_site`
CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_flora_territory.t_infos_site IS
'Extension de t_base_sites de gn_monitoring, permet d''avoir les infos complémentaires d''un site';

-- Table `cor_visit_grid`
CREATE TABLE cor_visit_grid (
    id_area integer NOT NULL,
    id_base_visit integer NOT NULL,
    presence boolean NOT NULL,
    uuid_base_visit UUID DEFAULT public.uuid_generate_v4()
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_grid IS
'Enregistrer la présence/absence d''une espèce dans une maille définie lors d''une visite';

-- Table `cor_visit_perturbation`
CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_flora_territory.cor_visit_perturbation IS
'Enregistrer les perturbations constatées lors d''une visite';

-- Add primary keys on previous tables'
ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT pk_id_t_infos_site
    PRIMARY KEY (id_infos_site);

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT pk_cor_visit_grid
    PRIMARY KEY (id_area, id_base_visit);

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT pk_cor_visit_perturbation
    PRIMARY KEY (id_base_visit, id_nomenclature_perturbation);


-- -----------------------------------------------------------------------------
-- FOREIGN KEYS

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_id_base_site
    FOREIGN KEY (id_base_site)
    REFERENCES gn_monitoring.t_base_sites (id_base_site)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_cd_nom
    FOREIGN KEY (cd_nom)
    REFERENCES taxonomie.taxref (cd_nom)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_base_visit
    FOREIGN KEY (id_base_visit)
    REFERENCES gn_monitoring.t_base_visits (id_base_visit)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_grid
    ADD CONSTRAINT fk_cor_visit_grid_id_area
    FOREIGN KEY (id_area)
    REFERENCES ref_geo.l_areas (id_area);

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit
    FOREIGN KEY (id_base_visit)
    REFERENCES gn_monitoring.t_base_visits (id_base_visit)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation
    FOREIGN KEY (id_nomenclature_perturbation)
    REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature)
    ON UPDATE CASCADE;


-- -----------------------------------------------------------------------------
-- VIEWS

-- Create view to export visits
CREATE OR REPLACE VIEW pr_monitoring_flora_territory.export_visits AS WITH
    observers AS (
        SELECT
            v.id_base_visit,
            string_agg(roles.nom_role::text || ' ' ||  roles.prenom_role::text, ',') AS observateurs,
            org.nom_organisme AS organisme
        FROM gn_monitoring.t_base_visits v
        JOIN gn_monitoring.cor_visit_observer observer ON observer.id_base_visit = v.id_base_visit
        JOIN utilisateurs.t_roles roles ON roles.id_role = observer.id_role
        JOIN utilisateurs.bib_organismes org ON roles.id_organisme = org.id_organisme
        GROUP BY v.id_base_visit, org.nom_organisme
    ),
    perturbations AS (
        SELECT
            v.id_base_visit,
            string_agg(n.label_default, ',') AS label_perturbation
        FROM gn_monitoring.t_base_visits v
        JOIN pr_monitoring_flora_territory.cor_visit_perturbation p ON v.id_base_visit = p.id_base_visit
        JOIN ref_nomenclatures.t_nomenclatures n ON p.id_nomenclature_perturbation = n.id_nomenclature
        GROUP BY v.id_base_visit
    ),
    area AS (
        SELECT bs.id_base_site,
            a.id_area,
            a.area_name
        FROM ref_geo.l_areas a
        JOIN gn_monitoring.t_base_sites bs ON ST_intersects(ST_TRANSFORM(a.geom, 4326), bs.geom)
        WHERE a.id_type=ref_geo.get_id_area_type('COM')
    )
-- All the meshes of a site and their visits
SELECT
    sites.id_base_site,
    cor.id_area,
    visits.id_base_visit,
    grid.presence,
    visits.id_digitiser,
    visits.visit_date_min,
    visits.comments,
    visits.uuid_base_visit,
    ar.geom,
    per.label_perturbation,
    obs.observateurs,
    obs.organisme,
    sites.base_site_name,
    taxon.nom_valide,
    taxon.cd_nom,
    area.area_name,
    ar.id_type
FROM gn_monitoring.t_base_sites sites
    JOIN gn_monitoring.cor_site_area AS cor
        ON (cor.id_base_site = sites.id_base_site)
    JOIN gn_monitoring.t_base_visits AS visits
        ON (sites.id_base_site = visits.id_base_site)
    LEFT JOIN pr_monitoring_flora_territory.cor_visit_grid AS grid
        ON (grid.id_area = cor.id_area AND grid.id_base_visit = visits.id_base_visit)
    JOIN observers AS obs
        ON (obs.id_base_visit = visits.id_base_visit)
    LEFT JOIN perturbations AS per
        ON (per.id_base_visit = visits.id_base_visit)
    JOIN area
        ON (area.id_base_site = sites.id_base_site)
    JOIN pr_monitoring_flora_territory.t_infos_site AS info
        ON (info.id_base_site = sites.id_base_site)
    JOIN taxonomie.taxref AS taxon
        ON (taxon.cd_nom = info.cd_nom)
    JOIN ref_geo.l_areas AS ar
        ON (ar.id_area = cor.id_area)
WHERE ar.id_type = ref_geo.get_id_area_type('M25m')
ORDER BY visits.id_base_visit ;


-- ----------------------------------------------------------------------------
-- Triggers
-- Idée:
-- + Un trigger pour vérifier si id_nomenclature_perturbation dans la table cor_visit_perturbation
--   correspond bien à celui stocké dans t_nomenclatures.

