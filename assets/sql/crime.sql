CREATE TABLE IF NOT EXISTS crime (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    district TEXT,
    crime_category TEXT NOT NULL,
    crime_type TEXT,
    cases INTEGER NOT NULL,
    UNIQUE(date, state_id, district, crime_category, crime_type)
);
