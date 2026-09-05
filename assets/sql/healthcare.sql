CREATE TABLE IF NOT EXISTS healthcare (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    district TEXT,
    hospital_type TEXT,
    beds INTEGER,
    staff_type TEXT,
    staff_count INTEGER,
    UNIQUE(date, state_id, district, hospital_type, staff_type)
);
