CREATE TABLE IF NOT EXISTS transport(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER,
    date TEXT NOT NULL,
    service_name TEXT NOT NULL,
    daily_ridership INTEGER NOT NULL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_transport_date ON transport(date);