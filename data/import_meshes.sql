-- Script SQL to import meshes (use with `import_meshes.sh`)
BEGIN;


ALTER TABLE :moduleSchema.:meshesTmpTable
    ALTER COLUMN :meshGeomColumn TYPE geometry(MULTIPOLYGON, :sridLocal)
    USING ST_Force2D(:meshGeomColumn);


-- Insert into l_areas
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


-- Insert into li_grids
INSERT INTO ref_geo.li_grids
    SELECT
        a.area_code,
        a.id_area,
        ST_XMin(ST_Extent(a.geom)),
        ST_XMax(ST_Extent(a.geom)),
        ST_YMin(ST_Extent(a.geom)),
        ST_YMax(ST_Extent(a.geom))
    FROM ref_geo.l_areas AS a
        JOIN :moduleSchema.:meshesTmpTable AS m
            ON (a.area_code = m.:meshNameColumn)
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.li_grids AS g
        WHERE g.id_grid = a.area_code
    )
    GROUP BY area_code, id_area ;

-- Clean database: remove temporary table
-- DROP TABLE :moduleSchema.:meshesTmpTable;


COMMIT;
