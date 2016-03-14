CREATE OR REPLACE VIEW bridge_z12toz14 AS
    SELECT *
    FROM osm_road_linestring
    WHERE is_bridge;

CREATE OR REPLACE VIEW layer_bridge AS (
    SELECT osm_id, timestamp, geometry FROM bridge_z12toz14
);

CREATE OR REPLACE FUNCTION changed_tiles_bridge(ts timestamp)
RETURNS TABLE (x INTEGER, y INTEGER, z INTEGER) AS $$
BEGIN
	RETURN QUERY (
		WITH changed_geometries AS (
		    SELECT osm_id, geometry FROM layer_bridge
		    WHERE timestamp = ts
		), changed_tiles AS (
		    SELECT DISTINCT c.osm_id, t.tile_x AS x, t.tile_y AS y, t.tile_z AS z
		    FROM changed_geometries AS c
		    INNER JOIN LATERAL overlapping_tiles(c.geometry, 14) AS t ON true
		)

		SELECT c.x, c.y, c.z FROM bridge_z12toz14 AS l
		INNER JOIN changed_tiles AS c ON c.osm_id = l.osm_id AND c.z BETWEEN 12 AND 14
	);
END;
$$ LANGUAGE plpgsql;
