ALTER TABLE design.junction
    ADD COLUMN display_geometry GEOMETRY(POLYGON,4326),
    ADD COLUMN display_image_ref TEXT;

ALTER TABLE design.poi
    ADD COLUMN lod_display_level INTEGER;
