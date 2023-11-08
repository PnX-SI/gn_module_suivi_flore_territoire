-- Script SQL to import meshes (use with `import_meshes.sh`)
BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Fix temporary meshes table geometry'
ALTER TABLE :moduleSchema.:meshesTmpTable
    ALTER COLUMN :meshGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
    USING ST_Force2D(:meshGeomColumn) ;

\echo '--------------------------------------------------------------------------------'
\echo 'Add new format columns if not exists'
ALTER TABLE :moduleSchema.:meshesTmpTable
    ADD COLUMN IF NOT EXISTS :meshTypeColumn VARCHAR(10) DEFAULT :'meshesCode',
    ADD COLUMN IF NOT EXISTS :meshActionColumn VARCHAR(1) DEFAULT 'A' ;

\echo '--------------------------------------------------------------------------------'
\echo 'Insert meshes into l_areas'
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, source, comment)
    SELECT
        ref_geo.get_id_area_type(:meshTypeColumn),
        :meshNameColumn,
        :meshNameColumn,
        :meshGeomColumn,
        ST_Centroid(:meshGeomColumn),
        :'meshesSource',
        CONCAT('SFT import date: ', :'importDate')
    FROM :moduleSchema.:meshesTmpTable AS m
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS a
            WHERE a.area_code = m.:meshNameColumn
        )
        AND m.:meshActionColumn = 'A' ;

\echo '--------------------------------------------------------------------------------'
\echo 'Update meshes into l_areas'
UPDATE ref_geo.l_areas AS a SET
    id_type = ref_geo.get_id_area_type(m.:meshTypeColumn),
    geom = m.:meshGeomColumn,
    centroid = ST_Centroid(m.:meshGeomColumn),
    source = :'meshesSource',
    comment = CONCAT(a.comment, ' ; SFT updated date: ', :'importDate')
FROM :moduleSchema.:meshesTmpTable AS m
WHERE a.area_code = m.:meshNameColumn
    AND m.:meshActionColumn = 'M' ;

\echo '--------------------------------------------------------------------------------'
\echo 'Insert meshes into li_grids'
INSERT INTO ref_geo.li_grids
    SELECT DISTINCT ON (a.area_code)
        a.area_code,
        a.id_area,
        ST_XMin(a.geom),
        ST_XMax(a.geom),
        ST_YMin(a.geom),
        ST_YMax(a.geom)
    FROM ref_geo.l_areas AS a
        JOIN :moduleSchema.:meshesTmpTable AS m
            ON (a.area_code = m.:meshNameColumn)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_grids AS g
            WHERE g.id_grid = a.area_code
        )
        AND m.:meshActionColumn = 'A' ;

\echo '--------------------------------------------------------------------------------'
\echo 'Update meshes into li_grids'
UPDATE ref_geo.li_grids AS g SET
    cxmin = ST_XMin(m.geom),
    cxmax = ST_XMax(m.geom),
    cymin = ST_YMin(m.geom),
    cymax = ST_YMax(m.geom)
FROM :moduleSchema.:meshesTmpTable AS m
WHERE g.id_grid = m.:meshNameColumn
    AND g.id_area = (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE area_code = m.:meshNameColumn
            AND id_type = ref_geo.get_id_area_type(m.:meshTypeColumn)
        LIMIT 1
    )
    AND m.:meshActionColumn = 'M' ;

-- -------------------------------------------------------------------------------------
COMMIT;
