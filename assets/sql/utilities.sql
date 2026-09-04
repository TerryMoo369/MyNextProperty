CREATE TABLE IF NOT EXISTS utilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    district TEXT,
    date TEXT NOT NULL,
    electricity REAL,
    piped_water REAL,
    sanitation REAL
);

CREATE INDEX IF NOT EXISTS idx_utilities_region_date ON utilities(state_id, date);