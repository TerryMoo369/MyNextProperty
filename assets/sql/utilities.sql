CREATE TABLE IF NOT EXISTS utilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    utility_type TEXT NOT NULL, -- 'electricity' or 'water'
    access_percentage REAL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_utilities_region_date ON utilities(region_id, date);