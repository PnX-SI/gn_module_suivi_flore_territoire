BEGIN;

-- Add new observer if not already exists
WITH test_exists AS (
    SELECT id_observer
    FROM :moduleSchema.:visitsOberserversTmpTable
    WHERE md5 = :'md5Sum'
)
INSERT INTO :moduleSchema.:visitsOberserversTmpTable (
    md5,
    firstname,
    lastname,
    organism
)
SELECT
    :'md5Sum',
    :'firstname',
    :'lastname',
    :'organism'
WHERE NOT EXISTS (SELECT id_observer FROM test_exists);


-- Link observer to visit data
INSERT INTO :moduleSchema.:visitsHasOberserversTmpTable
    (id_visit_meshe, id_observer)
VALUES (
    :visitId,
    :moduleSchema.get_id_observer_tmp(:'moduleSchema', :'visitsOberserversTmpTable', :'md5Sum')
) ;

COMMIT;
