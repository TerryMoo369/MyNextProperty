CREATE TABLE IF NOT EXISTS environment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    forest_reserve_area REAL,
    UNIQUE(date, state_id)
);
