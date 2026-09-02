CREATE TABLE IF NOT EXISTS fuelprice (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT UNIQUE NOT NULL,
    ron95 REAL,
    ron97 REAL,
    diesel REAL
);

CREATE INDEX IF NOT EXISTS idx_fuel_date ON fuelprice (date DESC);