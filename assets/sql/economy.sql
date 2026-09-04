CREATE TABLE IF NOT EXISTS economy (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    district TEXT,
    date TEXT NOT NULL,
    cpi_index REAL,
    cpi_division TEXT,
    income_mean REAL,
    income_median REAL,
    expenditure_mean REAL,
    poverty_rate REAL,
    gini_coefficient REAL,
    gdp_value REAL,
    gdp_sector TEXT,
    labour_force REAL,
    participation_rate REAL,
    unemployment_rate REAL
);

CREATE INDEX IF NOT EXISTS idx_econ_region_date ON economy(state_id, date);
CREATE INDEX IF NOT EXISTS idx_econ_district ON economy(district);
