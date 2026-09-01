CREATE TABLE IF NOT EXISTS transport (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER REFERENCES state(id),
    date TEXT NOT NULL,
    service_name TEXT NOT NULL,
    daily_ridership INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transport_date ON transport(date);