CREATE TABLE IF NOT EXISTS economy(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    income_median INTEGER,
    income_mean INTEGER,
    poverty_absolute REAL,
    cpi_index REAL
);

CREATE INDEX IF NOT EXISTS idx_econ_region_date ON economy(state_id, date);