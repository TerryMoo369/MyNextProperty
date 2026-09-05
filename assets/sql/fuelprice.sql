CREATE TABLE IF NOT EXISTS fuelprice (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    ron95 REAL,
    ron97 REAL,
    diesel REAL,
    diesel_eastmsia REAL,
    series_type TEXT
);
