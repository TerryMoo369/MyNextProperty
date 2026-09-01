CREATE TABLE IF NOT EXISTS regions (
    region_id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_name TEXT UNIQUE NOT NULL,
    latitude REAL,
    longitude REAL
);

CREATE INDEX IF NOT EXISTS idx_regions_name ON regions(state_name);