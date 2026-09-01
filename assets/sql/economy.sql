CREATE TABLE IF NOT EXISTS economy(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    income_median INTEGER,
    income_mean INTEGER,
    poverty_absolute REAL,
    cpi_index REAL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_econ_region_date ON economy(region_id, date);