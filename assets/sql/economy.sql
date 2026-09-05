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
    unemployment_rate REAL,
    UNIQUE(date, state_id, district, cpi_division, gdp_sector)
);
