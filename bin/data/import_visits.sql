-- Script SQL to import visits from temporary tables (use with `import_visits.sh`)

BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Update module and site id in temporary visit table'
WITH module AS (
    SELECT id_module AS id
    FROM gn_commons.t_modules
    WHERE module_code ILIKE :'moduleCode'
),
sites AS (
    SELECT id_base_site AS id, base_site_code AS site_code
    FROM gn_monitoring.t_base_sites
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET
    module_id = module.id,
    site_id = sites.id
FROM module, sites
WHERE vt.site_code = sites.site_code;


\echo '--------------------------------------------------------------------------------'
\echo 'Update meshe id in temporary visit table'
WITH meshes AS (
    SELECT a.id_area AS id, a.area_code AS code
    FROM ref_geo.l_areas AS a
    WHERE a.comment ILIKE 'SFT import%'
)
UPDATE :moduleSchema.:visitsTmpTable AS vt SET
    meshe_id = meshes.id
FROM meshes
WHERE vt.meshe_code = meshes.code;


\echo '--------------------------------------------------------------------------------'
\echo 'Add new base visits if not already exists'
INSERT INTO gn_monitoring.t_base_visits (
    id_base_site,
    id_dataset,
    id_module,
    visit_date_min,
    visit_date_max,
    comments
)
SELECT DISTINCT
    vt.site_id,
    vt.dataset_id,
    vt.module_id,
    vt.date_min,
    vt.date_max,
    ''
FROM :moduleSchema.:visitsTmpTable AS vt
WHERE NOT EXISTS (
    SELECT id_base_visit
    FROM gn_monitoring.t_base_visits
    WHERE
        id_base_site = vt.site_id
        AND id_dataset = vt.dataset_id
        AND id_module = vt.module_id
        AND visit_date_min = vt.date_min
        AND visit_date_max = vt.date_max
);


\echo '--------------------------------------------------------------------------------'
\echo 'Update visit id in temporary visit table'
WITH visits AS (
    SELECT
        id_base_visit AS id,
        uuid_base_visit AS uuid,
        id_base_site,
        id_dataset,
        id_module,
        visit_date_min,
        visit_date_max
    FROM gn_monitoring.t_base_visits
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET
    visit_id = v.id,
    visit_uuid = v.uuid
FROM visits AS v
WHERE
    v.id_base_site = vt.site_id
    AND v.id_dataset = vt.dataset_id
    AND v.id_module = vt.module_id
    AND v.visit_date_min = vt.date_min
    AND v.visit_date_max = vt.date_max;


\echo '--------------------------------------------------------------------------------'
\echo 'Update role id in temporary observers table (add new user (=role) if needed)'
WITH users AS (
    SELECT
        r.id_role AS id,
        r.prenom_role AS firstname,
        r.nom_role AS lastname,
        o.id_organisme AS id_organism,
        o.nom_organisme AS organism
    FROM utilisateurs.t_roles AS r
        JOIN utilisateurs.bib_organismes AS o
            ON (r.id_organisme = o.id_organisme)
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET
    role_id = u.id,
    role_added = False,
    organism_id = u.id_organism,
    organism_added = False
FROM users AS u
WHERE
    u.firstname ILIKE ot.firstname
    AND u.lastname ILIKE ot.lastname
    AND u.organism ILIKE ot.organism;

\echo '--------------------------------------------------------------------------------'
\echo 'Update not added organisms in temporary observers table'
WITH organisms AS (
    SELECT
        id_organisme AS id_organism,
        nom_organisme AS organism
    FROM utilisateurs.bib_organismes
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET
    organism_id = o.id_organism,
    organism_added = False
FROM organisms AS o
WHERE ot.organism = o.organism;

\echo '--------------------------------------------------------------------------------'
\echo 'Add new organism if not already exists'
INSERT INTO utilisateurs.bib_organismes (nom_organisme)
    SELECT DISTINCT ON (upper(organism)) organism
    FROM :moduleSchema.:visitsObserversTmpTable
    WHERE role_id IS NULL
        AND organism_id IS NULL
        AND organism != ''
        AND organism != 'INCONNU'
        AND organism IS NOT NULL
        AND upper(organism) NOT IN (
            SELECT DISTINCT ON (upper(nom_organisme)) upper(nom_organisme)
            FROM utilisateurs.bib_organismes
        )
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'Update new added organisms id in temporary observers table'
WITH organisms AS (
    SELECT
        id_organisme AS id_organism,
        nom_organisme AS organism
    FROM utilisateurs.bib_organismes
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET
    organism_id = o.id_organism,
    organism_added = True
FROM organisms AS o
WHERE ot.organism = o.organism
    AND ot.organism_added IS NULL;


\echo '--------------------------------------------------------------------------------'
\echo 'Add new users (=role)'
INSERT INTO utilisateurs.t_roles (
    prenom_role,
    nom_role,
    id_organisme,
    active,
    remarques,
    champs_addi
)
    SELECT
        firstname,
        lastname,
        organism_id,
        true,
        'Added by SFT import_visits.sh script.',
        json_build_object('sft', json_build_object('importDate', :'importDate'))
    FROM :moduleSchema.:visitsObserversTmpTable AS ot
    WHERE ot.role_id IS NULL
        AND (ot.organism_id IS NOT NULL OR ot.organism = 'INCONNU')
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'Update new added users in temporary observers table'
WITH users AS (
    SELECT id_role AS id,
        prenom_role AS firstname,
        nom_role AS lastname,
        id_organisme AS id_organism
    FROM utilisateurs.t_roles
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET
    role_id = u.id,
    role_added = True
FROM users AS u
WHERE ot.role_id IS NULL
    AND u.firstname ILIKE ot.firstname
    AND u.lastname ILIKE ot.lastname
    AND (u.id_organism = ot.organism_id OR ot.organism = 'INCONNU');


\echo '--------------------------------------------------------------------------------'
\echo 'Link added users to SFT observers list'
INSERT INTO utilisateurs.cor_role_liste (id_role, id_liste)
    SELECT role_id, :'observersListId'
    FROM :moduleSchema.:visitsObserversTmpTable
    WHERE role_added = True
ON CONFLICT DO NOTHING;


COMMIT;
BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Insert in gn_monitoring.cor_visit_observer'
INSERT INTO gn_monitoring.cor_visit_observer (id_base_visit, id_role)
    SELECT DISTINCT v.visit_id, o.role_id
    FROM :moduleSchema.:visitsTmpTable AS v
        JOIN :moduleSchema.:visitsHasObserversTmpTable AS vo
            ON (v.id_visit_meshe = vo.id_visit_meshe)
        JOIN :moduleSchema.:visitsObserversTmpTable AS o
            ON (vo.id_observer = o.id_observer)
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'Insert in cor_visit_grid (SFT schema)'
INSERT INTO :moduleSchema.cor_visit_grid (
    id_area,
    id_base_visit,
    uuid_base_visit,
    presence
)
    SELECT DISTINCT meshe_id, visit_id, visit_uuid,
        CASE
		    WHEN presence = 'pr' THEN True
		    WHEN presence = 'na' THEN False
	    END
    FROM :moduleSchema.:visitsTmpTable
    WHERE presence != 'np'
ON CONFLICT DO NOTHING;

-- TODO: manage "perturbation" if necessary

-- ----------------------------------------------------------------------------
COMMIT;
