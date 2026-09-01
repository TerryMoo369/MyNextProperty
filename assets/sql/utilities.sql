CREATE TABLE IF NOT EXISTS utilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    utility_type TEXT NOT NULL, -- 'electricity' or 'water'
    access_percentage REAL,
);

CREATE INDEX IF NOT EXISTS idx_utilities_region_date ON utilities(state_id, date);