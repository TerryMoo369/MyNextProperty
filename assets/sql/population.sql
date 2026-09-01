CREATE TABLE IF NOT EXISTS population (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    sex TEXT,
    age TEXT,
    ethnicity TEXT,
    population_000 REAL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_pop_region_date ON population(region_id, date);