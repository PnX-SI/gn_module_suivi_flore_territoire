-- Script SQL to import meshes (use with `import_meshes.sh`)
BEGIN;

ALTER TABLE :moduleSchema.:meshesTmpTable
    ALTER COLUMN :meshGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
    USING ST_Force2D(:meshGeomColumn);

INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
    SELECT
        ref_geo.get_id_area_type(:'meshesCode'),
        :meshNameColumn,
        :meshNameColumn,
        :meshGeomColumn,
        ST_Centroid(:meshGeomColumn),
        :'meshesSource'
    FROM :moduleSchema.:meshesTmpTable AS m
WHERE NOT EXISTS (
    SELECT 'X'
    FROM ref_geo.l_areas AS a
    WHERE a.area_code = m.:meshNameColumn
);

-- Clean database: remove temporary table
DROP TABLE :moduleSchema.:meshesTmpTable;

COMMIT;
