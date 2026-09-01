CREATE TABLE IF NOT EXISTS population (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    sex TEXT,
    age TEXT,
    ethnicity TEXT,
    population_000 REAL,
);

CREATE INDEX IF NOT EXISTS idx_pop_region_date ON population(state_id, date);