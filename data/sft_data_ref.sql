-- Script to insert references
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'REF GEO'

\echo 'Insert 25*25 meters  meshes new area type in `ref_geo.bib_areas_types`'
WITH test_exists AS (
    SELECT id_type
    FROM ref_geo.bib_areas_types
    WHERE type_code = :'meshesCode'
)
INSERT INTO ref_geo.bib_areas_types (type_code, type_name, type_desc)
SELECT :'meshesCode', :'meshesName', :'meshesDesc'
WHERE NOT EXISTS (SELECT id_type FROM test_exists)
RETURNING id_type ;


\echo '--------------------------------------------------------------------------------'
\echo 'TAXONOMY'

\echo 'Create monitored taxons list by SFT protocol'
WITH test_exists AS (
    SELECT id_liste
    FROM taxonomie.bib_listes
    WHERE nom_liste = :'taxonListName'
)
INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, regne, group2_inpn)
SELECT
    (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes),
    :'taxonListName',
    'Taxons suivis dans le protocole Suivi Flore Territoire',
    'Plantae',
    'Angiospermes'
WHERE NOT EXISTS (SELECT id_liste FROM test_exists)
RETURNING id_liste ;


\echo '--------------------------------------------------------------------------------'
\echo 'NOMENCLATURE'

\echo 'Create the "Perturbation" nomenclature type'
WITH test_exists AS (
    SELECT id_type
    FROM ref_nomenclatures.bib_nomenclatures_types
    WHERE mnemonique = :'perturbationCode'
)
INSERT INTO ref_nomenclatures.bib_nomenclatures_types
    (mnemonique, label_default, definition_default, label_fr, definition_fr, source)
SELECT
    :'perturbationCode',
    'Type de perturbations',
    'Nomenclature des types de perturbations.',
    'Type de perturbations',
    'Nomenclatures des types de perturbations.',
    :'perturbationSrc'
WHERE NOT EXISTS (SELECT id_type FROM test_exists)
RETURNING id_type ;


\echo '--------------------------------------------------------------------------------'
\echo 'NOMENCLATURE : SFT type site value'

\echo 'Add SFT nomenclature value for site type nomenclature (="TYPE_SITE")'
WITH test_exists AS (
    SELECT id_nomenclature
    FROM ref_nomenclatures.t_nomenclatures
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE')
        AND cd_nomenclature = :'siteTypeCode'
)
INSERT INTO ref_nomenclatures.t_nomenclatures
    (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr, source)
SELECT
    ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE'),
    :'siteTypeCode',
    'Zone de prospection',
    'Zone de prospection - suivi flore territoire',
    'Zone de prospection',
    'Zone de prospection issu du module Suivi Flore Territoire (SFT)',
    :'siteTypeSrc'
WHERE NOT EXISTS (SELECT id_nomenclature FROM test_exists)
RETURNING id_nomenclature ;

\echo '--------------------------------------------------------------------------------'
\echo 'COMMONS'

\echo 'Update SFT module infos'
UPDATE gn_commons.t_modules
SET
    module_label = 'Suivi Flore Territoire',
    module_picto = 'fa-leaf',
    module_desc = 'Module de Suivi de la Flore d''un Territoire'
WHERE module_code ILIKE :'moduleCode' ;

-- ----------------------------------------------------------------------------
COMMIT;
