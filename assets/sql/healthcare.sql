CREATE TABLE IF NOT EXISTS healthcare (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    district TEXT,
    date TEXT NOT NULL,
    hospital_type TEXT,
    beds INTEGER,
    staff_type TEXT,
    staff_count INTEGER
);

CREATE INDEX IF NOT EXISTS idx_healthcare_state_date ON healthcare(state_id, date);
