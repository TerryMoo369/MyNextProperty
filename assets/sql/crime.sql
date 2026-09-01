CREATE TABLE IF NOT EXISTS crime (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    crime_category TEXT NOT NULL,
    cases INTEGER NOT NULL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_crime_region_date ON crime(region_id, date);