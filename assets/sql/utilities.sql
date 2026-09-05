CREATE TABLE IF NOT EXISTS utilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL UNIQUE,
    district TEXT,
    electricity REAL,
    piped_water REAL,
    sanitation REAL
);
