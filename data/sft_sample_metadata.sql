BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create a sample acquisition framework for this module'
INSERT INTO gn_meta.t_acquisition_frameworks (
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    acquisition_framework_parent_id,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date
)
SELECT
    '28917b9b-2e17-4bbe-8207-1254a9748844',
    'Suivis Flore Sentinelle',
    'Ensemble des suivis réalisés dans les Alpes françaises dans le cadre du réseau Flore Sentinelle.',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    'Alpes françaises.',
    'Suivi, Alpes, France, Flore, Réseau.',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    'Identifier et comprendre les dynamiques démographiques des espèces végétales et des habitats, sentinelles pour le suivi des changements globaux dans les Alpes françaises.',
    'Flore',
    NULL,
    false,
    '2009-01-01',
    NULL
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_meta.t_acquisition_frameworks AS tafe
    WHERE tafe.unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert links between acquisition framework and actor'
INSERT INTO gn_meta.cor_acquisition_framework_actor (
    id_acquisition_framework,
    id_role,
    id_organism,
    id_nomenclature_actor_role
) VALUES (
    (
        SELECT id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks
        WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
    ),
    NULL,
    1,
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert links between acquisition framework and objectifs'
INSERT INTO gn_meta.cor_acquisition_framework_objectif (
    id_acquisition_framework,
    id_nomenclature_objectif
) VALUES
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '4')
    ),
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '5')
    ),
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '6')
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert links between acquisition framework and SINP "volet"'
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
    id_acquisition_framework,
    id_nomenclature_voletsinp
) VALUES
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
        ),
        ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1')
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Create datasets in acquisition framework'
INSERT INTO gn_meta.t_datasets (
    unique_dataset_id,
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    active,
    validable
) VALUES (
    'e4af0284-740d-42d3-8052-fd2912f07d5b',
    (
        SELECT id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks
        WHERE unique_acquisition_framework_id = '28917b9b-2e17-4bbe-8207-1254a9748844'
    ),
    'Suivis Flore Territoire',
    :'moduleCode',
    'Données acquises dans le cadre du protocole Suivi Flore Territoire.',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    NULL,
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '5.2'),
    NULL,
    NULL,
    NULL,
    NULL,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    true
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert links between datasets and actors'
INSERT INTO gn_meta.cor_dataset_actor (
    id_dataset,
    id_role,
    id_organism,
    id_nomenclature_actor_role
) VALUES
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = 'e4af0284-740d-42d3-8052-fd2912f07d5b'
        ),
        NULL,
        1,
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert links between datasets and modules'
INSERT INTO gn_commons.cor_module_dataset (
    id_module, id_dataset
) VALUES
    (
        gn_commons.get_id_module_bycode(:'moduleCode'),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = 'e4af0284-740d-42d3-8052-fd2912f07d5b'
        )
    ) ;


-- ----------------------------------------------------------------------------
COMMIT;
