-- Script SQL to import meshes (use with `import_meshes.sh`)
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Fix temporary meshes table geometry'
ALTER TABLE :moduleSchema.:meshesTmpTable
    ALTER COLUMN :meshGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
    USING ST_Force2D(:meshGeomColumn);


\echo '--------------------------------------------------------------------------------'
\echo 'Insert meshes into l_areas'
INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source, comment)
    SELECT
        ref_geo.get_id_area_type(:'meshesCode'),
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
    ) ;


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
    );

-- -------------------------------------------------------------------------------------
COMMIT;
